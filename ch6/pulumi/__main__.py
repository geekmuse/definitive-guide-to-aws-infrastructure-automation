import random
import pulumi
import pulumi_aws as aws
import boto3

## Get config and set some globals
conf = pulumi.Config()
_APP = 'pulumi'
_REGION = boto3.session.Session().region_name
_OS = conf.require('Os')
_AMI = conf.require(f'AmiByOs.{_REGION}.{_OS}')
_PORT = conf.require_int(f'ConnectPortByOs.{_OS}')
_INST_TYPE = conf.require('InstanceType')
_AZ = conf.require('Az')
_STACK = pulumi.get_stack()

## Instatiate boto client and gather context
ec2 = boto3.client('ec2', region_name=_REGION)
vpc = ec2.describe_vpcs(
        Filters=[
        {
            'Name': 'tag:Name',
            'Values': [_STACK]
        }]
    )['Vpcs'][0]['VpcId']

subnets_response = ec2.describe_subnets(
            Filters=[
                {
                    'Name': 'tag:Tier',
                    'Values': ['public']
                },
                {
                    'Name': 'vpc-id',
                    'Values': [vpc]
                }
            ]
        )

subnets = {}
for s in subnets_response['Subnets']:
    subnets[s['AvailabilityZone']] = s['SubnetId']

## Create security group resource
sg = aws.ec2.SecurityGroup(
        resource_name=f'{_APP}-sg',
        name=f'{_APP}-sg',
        vpc_id=vpc,
        ingress=[
            {
                'protocol': 'tcp',
                'from_port': _PORT,
                'to_port': _PORT,
                'cidr_blocks': ['0.0.0.0/0']
            }
        ],
        egress=[
            {
                'protocol': -1,
                'from_port': 0,
                'to_port': 0,
                'cidr_blocks': ['0.0.0.0/0']
            }
        ]
    )

## Create EC2 instance resource
inst = aws.ec2.Instance(
        resource_name=f'{_APP}-inst',
        associate_public_ip_address=True,
        subnet_id=subnets[_AZ],
        vpc_security_group_ids=[sg.id],
        ami=_AMI,
        instance_type=_INST_TYPE
    )

## Export values of interest
pulumi.export('public_ip', inst.public_ip)
pulumi.export('public_dns', inst.public_dns)