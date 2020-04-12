from pulumi import (
    Config,
    Output,
    get_project,
    get_stack
)
from pulumi_aws import (
    ec2,
    cloudwatch as cw,
    iam
)
import boto3
import ipaddress

conf = Config()
ha = conf.require_bool('highAvailability')
_env = get_stack()
APP = f"{get_project()}-{_env}"
TIERS = ['public', 'app', 'data']
region = boto3.session.Session().region_name
cidr = conf.require(f"cidr.{region}")
aws_dns = conf.require_bool('useAwsDns')
max_azs = conf.require_int('maxAzs')


client = boto3.client('ec2', region_name=region)

vpc = ec2.Vpc(
        resource_name=f'{APP}-vpc',
        cidr_block=cidr,
        enable_dns_hostnames=aws_dns,
        enable_dns_support=aws_dns,
        instance_tenancy='default',
        tags={
            'Name': APP,
            'Environment': _env
        }
    )

igw = ec2.InternetGateway(
        resource_name=f'{APP}-igw',
        vpc_id=vpc.id
    )

azs_response = client.describe_availability_zones(
        Filters=[
            {
                'Name': 'region-name',
                'Values': [region]
            },
            {
                'Name': 'state',
                'Values': ['available']
            }
        ]
    )

azs = [x['ZoneName'] for x in azs_response['AvailabilityZones']]
if len(azs) < max_azs:
    max_azs = len(azs)
subnet_cidrs = list(ipaddress.ip_network(cidr).subnets(new_prefix=20))
subnets = {}
for i in TIERS:
    subnets[i] = {}

k = 0
for i in TIERS:
    for j in range(0, max_azs):
        subnets[i][j] = ec2.Subnet(
                resource_name=f"{APP}-{i}{j}",
                availability_zone=azs[j],
                cidr_block=str(subnet_cidrs[k]),
                map_public_ip_on_launch=True if i == 'public' else False,
                vpc_id=vpc.id,
                tags={
                    'Name': f"{i}{j}",
                    'Environment': _env,
                    'Tier': i
                }
            )

        k += 1

rtb_pub = ec2.RouteTable(
    f"{APP}-rtb-pub",
    vpc_id=vpc.id,
    tags={
        'Name': 'rtb-pub',
        'Environment': _env
    }
)

rte_pub = ec2.Route(
    f"{APP}-rte-pub",
    destination_cidr_block="0.0.0.0/0",
    gateway_id=igw.id,
    route_table_id=rtb_pub.id
)

for i in subnets["public"]:
    ec2.RouteTableAssociation(
        f"{APP}-rtb-assoc-pub{i}",
        route_table_id=rtb_pub.id,
        subnet_id=subnets["public"][i]
    )

rtb_privs = []
if not ha:
    eip = ec2.Eip(
        f"{APP}-eip0",
        vpc=True,
        tags={
            'Name': f"{APP}-eip0",
            'Environment': _env
        }
    )
    ngw = ec2.NatGateway(
        f"{APP}-ngw0",
        allocation_id=eip.id,
        subnet_id=subnets["public"][0],
        tags={
            'Name': f"{APP}-ngw0",
            'Environment': _env
        }
    )
    rtb_priv = ec2.RouteTable(
        f"{APP}-rtb-priv0",
        vpc_id=vpc.id,
        tags={
            'Name': 'rtb-priv',
            'Environment': _env
        }
    )
    rtb_privs.append(rtb_priv)
    rte_priv = ec2.Route(
        f"{APP}-rte-priv0",
        destination_cidr_block="0.0.0.0/0",
        nat_gateway_id=ngw.id,
        route_table_id=rtb_priv.id
    )
    for i in subnets["app"]:
        ec2.RouteTableAssociation(
            f"{APP}-rtb-assoc-app{i}",
            route_table_id=rtb_priv.id,
            subnet_id=subnets["app"][i]
        )
    for i in subnets["data"]:
        ec2.RouteTableAssociation(
            f"{APP}-rtb-assoc-data{i}",
            route_table_id=rtb_priv.id,
            subnet_id=subnets["data"][i]
        )
else:
    for i in range(0, max_azs):
        eip = ec2.Eip(
            f"{APP}-eip{i}",
            vpc=True,
            tags={
                'Name': f"{APP}-eip{i}",
                'Environment': _env
            }
        )
        ngw = ec2.NatGateway(
            f"{APP}-ngw{i}",
            allocation_id=eip.id,
            subnet_id=subnets["public"][i],
            tags={
                'Name': f"{APP}-ngw{i}",
                'Environment': _env
            }
        )
        rtb_priv = ec2.RouteTable(
            f"{APP}-rtb-priv{i}",
            vpc_id=vpc.id,
            tags={
                'Name': f'rtb-priv{i}',
                'Environment': _env
            }
        )
        rtb_privs.append(rtb_priv)
        ec2.Route(
            f"{APP}-rte-priv{i}",
            destination_cidr_block="0.0.0.0/0",
            nat_gateway_id=ngw.id,
            route_table_id=rtb_priv.id
        )
        ec2.RouteTableAssociation(
            f"{APP}-rtb-assoc-app{i}",
            route_table_id=rtb_priv.id,
            subnet_id=subnets["app"][i]
        )
        ec2.RouteTableAssociation(
            f"{APP}-rtb-assoc-data{i}",
            route_table_id=rtb_priv.id,
            subnet_id=subnets["data"][i]
        )

log_group = cw.LogGroup(
    f"{APP}-flowlog-lg",
    name=f"/{get_project()}/flowlogs/{_env}",
    retention_in_days=30,
    tags={
        'Name': f"{APP}-flowlog-lg",
        'Environment': _env
    }
)

cw_info = Output.all(log_group.arn)
policy_doc = cw_info.apply(
    lambda info: """{{
    "Version": "2012-10-17",
    "Statement": [
        {{
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams"
            ],
            "Effect": "Allow",
            "Resource": "{0}"
        }}
    ]
}}
""".format(info[0]))

assume_role_policy_doc = """{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "cwTrust",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "vpc-flow-logs.amazonaws.com"
            }
        }
    ]
}
"""

policy = iam.Policy(
    f"{APP}-flowlog-policy",
    name=f"{APP}-flowlog",
    path="/",
    policy=policy_doc
)

role = iam.Role(
    f"{APP}-flowlog-role",
    assume_role_policy=assume_role_policy_doc,
    name=f"{APP}-flowlog-role",
    path="/",
    tags={
        'Name': f"{APP}-flowlog-role",
        'Environment': _env
    }
)

attach_info = Output.all(role.name, policy.arn)
role_attach = attach_info.apply(
    lambda info: iam.RolePolicyAttachment(
        f"{APP}-flowlog-role-attach",
        policy_arn=info[1],
        role=info[0]
    )
)

flowlog_info = Output.all(role.arn, log_group.arn)
flowlog = flowlog_info.apply(
    lambda info: ec2.FlowLog(
        f"{APP}-flowlog",
        iam_role_arn=info[0],
        log_destination=info[1],
        traffic_type="ALL",
        vpc_id=vpc.id,
        tags={
            'Name': f"{APP}-flowlog",
            'Environment': _env
        }
    )
)
