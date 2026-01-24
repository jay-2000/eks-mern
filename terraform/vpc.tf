#############################################
# AVAILABILITY ZONES (REQUIRED FOR EKS)
#############################################
data "aws_availability_zones" "available" {
  state = "available"
}

#############################################
# VPC
#############################################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "mern-vpc"
  }
}

#############################################
# PUBLIC SUBNETS (3 – MULTI AZ)
#############################################
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

#############################################
# PRIVATE SUBNETS (3 – MULTI AZ)
#############################################
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

#############################################
# INTERNET GATEWAY
#############################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mern-igw"
  }
}

#############################################
# NAT GATEWAY (SINGLE – COST OPTIMIZED)
#############################################
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat_eip.id

  tags = {
    Name = "mern-natgw"
  }
}

#############################################
# PUBLIC ROUTE TABLE
#############################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "mern-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 3
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public[count.index].id
}

#############################################
# PRIVATE ROUTE TABLE
#############################################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "mern-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = 3
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private[count.index].id
}
