# These correspond to 3-1 Parameters
variable "key_name" {
  type = "string"
  description = "Name of an existing EC2 KeyPair to enable access to the instance"
  default = ""
}

variable "operating_system" {
  type = "string"
  description = "Chosen operating system"
  default = "AmazonLinux2"
}

variable "instance_type" {
  type = "string"
  description = "EC2 instance type"
  default = "t2.small"
}

variable "public_location" {
  type = "string"
  description = "The IP address range that can be used to connect to the EC2 instances"
  default = "0.0.0.0/0"
}

# These correspond to 3-1 Mappings
variable "connect_port_by_os" {
  type = "map"
  description = "Port mappings for operating systems"
  default = {
    Windows2016Base = "3389"
    AmazonLinux2 = "22"
  }
}

variable "ami_by_region_os" {
  type = "map"
  description = "AMI ID by region and OS"
  default = {
    us-east-1 = {
      Windows2016Base = "ami-06bee8e1000e44ca4"
      AmazonLinux2 = "ami-0c6b1d09930fac512"
    }
    us-west-2 = {
      Windows2016Base = "ami-07f35a597a32e470d"
      AmazonLinux2 = "ami-0cb72367e98845d43"
    }
  }
}