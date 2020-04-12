#!/usr/bin/env python

from troposphere import Base64, FindInMap, GetAtt
from troposphere import Parameter, Output, Ref, Template, Condition, Equals, And, Or, Not, If
import troposphere.ec2 as ec2

tpl = Template()
tpl.add_version("2010-09-09")
tpl.add_description("Creates EC2 security group and instance")

params= {}
conditions = {}
mappings = {}
resources = {}

params['keyname'] = tpl.add_parameter(
    Parameter(
        "KeyName",
        Description="Name of an existing EC2 KeyPair to enable access to the instance",
        Type="String",
        Default="",
        ConstraintDescription="must be a string"
    )
)

params['os'] = tpl.add_parameter(
    Parameter(
        "OperatingSystem",
        Description="Chosen operating system",
        Type="String",
        Default="AmazonLinux2",
        AllowedValues=[
            "AmazonLinux2",
            "Windows2016Base"
        ]
    )
)

params['instance_type'] = tpl.add_parameter(
    Parameter(
        "InstanceType",
        Description="EC2 instance type",
        Type="String",
        Default="t2.small",
        AllowedValues=[
            "t2.nano", "t2.micro", "t2.small", "t2.medium",
            "m4.large", "m4.xlarge"
        ]
    )
)

params['pub_loc'] = tpl.add_parameter(
    Parameter(
        "PublicLocation",
        Description="The IP address range that can be used to connect to the EC2 instances",
        Type="String",
        MinLength=9,
        MaxLength=18,
        Default="0.0.0.0/0",
        AllowedPattern="(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/(\d{1,2})",
        ConstraintDescription="must be a valid IP CIDR range of the form x.x.x.x/x"
    )
)

conditions['has_kp'] = tpl.add_condition(
    "HasKeypair",
    Not(
        Equals(Ref("KeyName"), "")
    )
)

mappings['global'] = tpl.add_mapping(
    'Global', {
        "ConnectPortByOs": {
            "Windows2016Base": 3389,
            "AmazonLinux2": 22,
        },
    }
)

mappings['ami_by_os'] = tpl.add_mapping(
    'AmiByOs', {
        "us-east-1": {
            "Windows2016Base": "ami-06bee8e1000e44ca4",
            "AmazonLinux2": "ami-0c6b1d09930fac512",
        },
        "us-west-2": {
            "Windows2016Base": "ami-07f35a597a32e470d",
            "AmazonLinux2": "ami-0cb72367e98845d43",
        },
    }
)

resources['sg'] = tpl.add_resource(
    ec2.SecurityGroup(
        "InstanceSg",
        GroupDescription="Enable SSH and HTTP access on the inbound port",
        SecurityGroupIngress=[
            ec2.SecurityGroupRule(
                IpProtocol="tcp",
                FromPort=FindInMap("Global", "ConnectPortByOs", Ref(params['os'])),
                ToPort=FindInMap("Global", "ConnectPortByOs", Ref(params['os'])),
                CidrIp=Ref(params['pub_loc']),
            )
        ]
    )
)

resources['ec2'] = tpl.add_resource(
    ec2.Instance(
        "Ec2Instance",
        ImageId=FindInMap("AmiByOs", Ref("AWS::Region"), Ref(params['os'])),
        InstanceType=Ref(params['instance_type']),
        KeyName=If(conditions['has_kp'], Ref(params['keyname']), Ref("AWS::NoValue")),
        SecurityGroups=[
            Ref(resources['sg']),
        ],
    )
)

tpl.add_output([
    Output(
        "InstanceId",
        Description="InstanceId of the EC2 instance",
        Value=Ref(resources['ec2']),
    ),
    Output(
        "AZ",
        Description="AZ of the EC2 instance",
        Value=GetAtt(resources['ec2'], "AvailabilityZone"),
    ),
    Output(
        "PublicDNS",
        Description="Public DNSName of the EC2 instance",
        Value=GetAtt(resources['ec2'], "PublicDnsName"),
    ),
    Output(
        "PublicIP",
        Description="Public IP address of the EC2 instance",
        Value=GetAtt(resources['ec2'], "PublicIp"),
    )
])

print(tpl.to_yaml())