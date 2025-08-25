resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
    availability_zone = "eu-west-2a"

  tags = {
    Name = "public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
    availability_zone = "eu-west-2a"

  tags = {
    Name = "public2"
  }
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
    availability_zone = "eu-west-2a"

  tags = {
    Name = "private1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "private2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat1" {
  domain   = "vpc"
}
resource "aws_eip" "nat2" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "main1" {
  allocation_id = aws_eip.nat1.id
  subnet_id    = aws_subnet.public1.id

  tags = {
    Name = "main1"
  }
  depends_on = [ aws_internet_gateway.main ]
}

resource "aws_nat_gateway" "main2" {
  allocation_id = aws_eip.nat2.id
  subnet_id    = aws_subnet.public2.id

  tags = {
    Name = "main2"
  }
  depends_on = [ aws_internet_gateway.main ]
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main1.id
  }

  tags = {
    Name = "private1"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main2.id
  }

  tags = {
    Name = "private2"
  }
  }

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}
