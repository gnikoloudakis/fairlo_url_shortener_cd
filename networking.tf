

# Internet Gateway | It gives internet access to public subnets
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "AWS internal services VPC Internet Gateway"
  }
}

# Public Subnet 1 | use two subnets for high availability
resource "aws_subnet" "vpc_public_subnet_1" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.0.0/18"
  map_public_ip_on_launch = true

  tags = {
    "aws-tutorial:subnet-name" = "Public"
    "aws-tutorial:subnet-type" = "Public"
    Name                       = "VPC/PublicSubnet1"
  }
}

# Public Subnet 2
resource "aws_subnet" "vpc_public_subnet_2" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.64.0/18"
  map_public_ip_on_launch = true

  tags = {
    "aws-tutorial:subnet-name" = "Public"
    "aws-tutorial:subnet-type" = "Public"
    Name                       = "VPC/PublicSubnet2"
  }
}

# Private Subnet 1
resource "aws_subnet" "vpc_private_subnet_1" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.128.0/18"
  map_public_ip_on_launch = false

  tags = {
    "aws-tutorial:subnet-name" = "Private"
    "aws-tutorial:subnet-type" = "Private"
    Name                       = "VPC/PrivateSubnet1"
  }
}

# Private Subnet 2
resource "aws_subnet" "vpc_private_subnet_2" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.192.0/18"
  map_public_ip_on_launch = false

  tags = {
    "aws-tutorial:subnet-name" = "Private"
    "aws-tutorial:subnet-type" = "Private"
    Name                       = "VPC/PrivateSubnet2"
  }
}

# Public Route Table 1
resource "aws_route_table" "vpc_public_subnet_1_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PublicSubnet1/RouteTable"
  }
}

# Public Route Table 2
resource "aws_route_table" "vpc_public_subnet_2_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PublicSubnet2/RouteTable"
  }
}

# Private Route Table 1
resource "aws_route_table" "vpc_private_subnet_1_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PrivateSubnet1/RouteTable"
  }
}

# Private Route Table 2
resource "aws_route_table" "vpc_private_subnet_2_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PrivateSubnet2/RouteTable"
  }
}

# Route Table Associations
resource "aws_route_table_association" "vpc_public_subnet_1_route_table_association" {
  route_table_id = aws_route_table.vpc_public_subnet_1_route_table.id
  subnet_id      = aws_subnet.vpc_public_subnet_1.id
}

resource "aws_route_table_association" "vpc_public_subnet_2_route_table_association" {
  route_table_id = aws_route_table.vpc_public_subnet_2_route_table.id
  subnet_id      = aws_subnet.vpc_public_subnet_2.id
}

resource "aws_route_table_association" "vpc_private_subnet_1_route_table_association" {
  route_table_id = aws_route_table.vpc_private_subnet_1_route_table.id
  subnet_id      = aws_subnet.vpc_private_subnet_1.id
}

resource "aws_route_table_association" "vpc_private_subnet_2_route_table_association" {
  route_table_id = aws_route_table.vpc_private_subnet_2_route_table.id
  subnet_id      = aws_subnet.vpc_private_subnet_2.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "vpc_public_subnet_1_eip" {
  domain = "vpc"

  tags = {
    Name = "VPC/PublicSubnet1/ElasticIP"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

resource "aws_eip" "vpc_public_subnet_2_eip" {
  domain = "vpc"

  tags = {
    Name = "VPC/PublicSubnet2/ElasticIP"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

# NAT Gateways
resource "aws_nat_gateway" "vpc_public_subnet_1_nat_gateway" {
  subnet_id     = aws_subnet.vpc_public_subnet_1.id
  allocation_id = aws_eip.vpc_public_subnet_1_eip.id

  tags = {
    Name = "VPC/PublicSubnet1/NATGateway"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

resource "aws_nat_gateway" "vpc_public_subnet_2_nat_gateway" {
  subnet_id     = aws_subnet.vpc_public_subnet_2.id
  allocation_id = aws_eip.vpc_public_subnet_2_eip.id

  tags = {
    Name = "VPC/PublicSubnet2/NATGateway"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

# Routes
resource "aws_route" "vpc_public_subnet_1_default_route" {
  route_table_id         = aws_route_table.vpc_public_subnet_1_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id
}

resource "aws_route" "vpc_public_subnet_2_default_route" {
  route_table_id         = aws_route_table.vpc_public_subnet_2_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id
}

resource "aws_route" "vpc_private_subnet_1_default_route" {
  route_table_id         = aws_route_table.vpc_private_subnet_1_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_public_subnet_1_nat_gateway.id
}

resource "aws_route" "vpc_private_subnet_2_default_route" {
  route_table_id         = aws_route_table.vpc_private_subnet_2_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_public_subnet_2_nat_gateway.id
}
