#!/usr/bin/env python

from BaseDeployment import AbstractDeployment
from troposphere import FindInMap, Parameter, Output, Ref, Template
import troposphere.ec2 as ec2

class DevDeployment(AbstractDeployment):

    def __init__(self, template=None):
        super(DevDeployment, self).__init__('dev')
        if template:
            self.template = template
        else:
            self.template = Template()
            self.template.add_version("2010-09-09")
            self.template.add_description("DevDeployment EC2 instance")

            self.template.add_parameter(
                Parameter(
                    "Os",
                    Description="Chosen operating system",
                    Type="String",
                    Default="AmazonLinux2",
                    AllowedValues=[
                        "AmazonLinux2",
                        "Windows2016Base",
                    ]
                )
            )

            self.template.add_mapping(
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

            self.template.add_resource(
                ec2.Instance(
                    "DevEc2",
                    ImageId=FindInMap("AmiByOs", Ref("AWS::Region"), Ref("Os")),
                    InstanceType="t2.small",
                )
            )


class ProdDeployment(AbstractDeployment):

    def __init__(self, template=None):
        super(ProdDeployment, self).__init__('prod')
        if template:
            self.template = template
        else:
            self.template = Template()
            self.template.add_version("2010-09-09")
            self.template.add_description("ProdDeployment EC2 instance")

            self.template.add_parameter(
                Parameter(
                    "Os",
                    Description="Chosen operating system",
                    Type="String",
                    Default="AmazonLinux2",
                    AllowedValues=[
                        "AmazonLinux2",
                        "Windows2016Base",
                    ]
                )
            )

            self.template.add_mapping(
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

            self.template.add_resource(
                ec2.Instance(
                    "ProdEc2",
                    ImageId=FindInMap("AmiByOs", Ref("AWS::Region"), Ref("Os")),
                    InstanceType="m4.large",
                )
            )