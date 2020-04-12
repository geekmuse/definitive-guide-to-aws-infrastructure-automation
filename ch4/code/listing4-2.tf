# default configuration
provider "aws" {
  region = "us-east-1"
}

# alternative, aliased configuration
provider "aws" {
  alias  = "uw2"
  region = "us-west-2"
}

resource "aws_instance" "primary" {
  # ...
}

resource "aws_instance" "failover" {
  provider = aws.uw2

  # ...
}
