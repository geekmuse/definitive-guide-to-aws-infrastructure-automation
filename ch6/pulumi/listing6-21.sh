#!/bin/bash

pulumi config set AmiByOs.us-east-1.AmazonLinux2 ami-0c6b1d09930fac512
pulumi config set AmiByOs.us-east-1.Windows2016Base ami-06bee8e1000e44ca4
pulumi config set AmiByOs.us-west-2.AmazonLinux2 ami-0cb72367e98845d43
pulumi config set AmiByOs.us-west-2.Windows2016Base ami-07f35a597a32e470d
pulumi config set ConnectPortByOs.AmazonLinux2 22
pulumi config set ConnectPortByOs.Windows2016Base 3389
pulumi config set Os AmazonLinux2
pulumi config set InstanceType t2.nano
pulumi config set Az us-east-1c
