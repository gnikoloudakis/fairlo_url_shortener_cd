
# VPC
resource "aws_vpc" "my_aws_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "VPC network for internal services to communicate securely"
  }
}
