#create VPC
resource "aws_vpc" "Rock_Ltd" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames= true

  tags = {
    Name = "Rock_Ltd"
  }
}

# Declare the data source
data "aws_availability_zones" "availability_zone" {}

#create public subnets1
resource "aws_subnet" "web_pub_sub1" {
  vpc_id     = aws_vpc.Rock_Ltd.id
  cidr_block = var.web_pub_sub1_cidr
  availability_zone = data.aws_availability_zones.availability_zone.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "web_pub_sub1"
  }
}

#create public subnet2
resource "aws_subnet" "web_pub_sub2" {
  vpc_id     = aws_vpc.Rock_Ltd.id
  cidr_block = var.web_pub_sub2_cidr
  availability_zone = data.aws_availability_zones.availability_zone.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "web_pub_sub2"
  }
}

#app private subnet1 
resource "aws_subnet" "app_priv_sub1" {
  vpc_id     = aws_vpc.Rock_Ltd.id
  cidr_block = var.app_priv_sub1_cidr
  availability_zone = data.aws_availability_zones.availability_zone.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "app_priv_sub1"
  }
}

#app private subnet2
resource "aws_subnet" "app_priv_sub2" {
  vpc_id     = aws_vpc.Rock_Ltd.id
  cidr_block = var.app_priv_sub2_cidr
  availability_zone = data.aws_availability_zones.availability_zone.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "app_priv_sub2"
  }
}

#Public Route TableA
resource "aws_route_table" "public_route_tableA" {
  vpc_id = aws_vpc.Rock_Ltd.id


  tags = {
    Name = "public_route_tableA"
  }
}


#Public Route TableB
resource "aws_route_table" "public_route_tableB" {
  vpc_id = aws_vpc.Rock_Ltd.id

  tags = {
    Name = "public_route_table2"
  }
}


#Public Side Route_table association for web_public_subnet1
resource "aws_route_table_association" "web-pub-sub1_assoc" {
  subnet_id      = aws_subnet.web_pub_sub1.id
  route_table_id = aws_route_table.public_route_tableA.id
}

#Public Side Route_table association for web_public_subnet2
resource "aws_route_table_association" "web-pub-sub2_assoc" {
  subnet_id      = aws_subnet.web_pub_sub2.id
  route_table_id = aws_route_table.public_route_tableB.id
}

#Private Side Route_table association for app_private_subnet1
resource "aws_route_table_association" "app_priv_sub1" {
  subnet_id      = aws_subnet.app_priv_sub1.id
  route_table_id = aws_route_table.private_route_tableA.id
}

#Private Side Route_table association for app_private_subnet2
resource "aws_route_table_association" "app_priv_sub2" {
  subnet_id      = aws_subnet.app_priv_sub2.id
  route_table_id = aws_route_table.private_route_tableB.id
}


#private route table1
resource "aws_route_table" "private_route_tableA" {
  vpc_id = aws_vpc.Rock_Ltd.id

  tags = {
    Name = "private_route_tableA"
  }
}

#private route tableB
resource "aws_route_table" "private_route_tableB" {
  vpc_id = aws_vpc.Rock_Ltd.id

    tags = {
    Name = "private_route_tableB"
  }
}

#internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Rock_Ltd.id

tags = {
    Name = "igw"
  }
}

#internet Gateway Routing to the pub_1 side
resource "aws_route" "pub_sub_route1" {
  route_table_id            = aws_route_table.public_route_tableA.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
  }

#internet Gateway Routing pub_2
resource "aws_route" "pub_sub_route2" {
  route_table_id            = aws_route_table.public_route_tableB.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
  }

#EIP Address for az1
resource "aws_eip" "eip_for_nat_gateway_az1" {
  vpc                       = true

  tags = {
    Name                    = "Nat Gateway az1 eip"
  }
}

#EIP Address for az2
resource "aws_eip" "eip_for_nat_gateway_az2" {
  vpc                       = true

  tags = {
    Name                    = "Nat Gateway az2 eip"
  }
}

#Nat Gateway az1
resource "aws_nat_gateway" "nat_gateway_az1" {
  allocation_id = aws_eip.eip_for_nat_gateway_az1.id
  subnet_id     = aws_subnet.web_pub_sub1.id

  tags = {
    Name = "Nat_Gateway_az1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

#Nat Gateway az2
resource "aws_nat_gateway" "nat_gateway_az2" {
  allocation_id = aws_eip.eip_for_nat_gateway_az2.id
  subnet_id     = aws_subnet.web_pub_sub2.id

  tags = {
    Name = "Nat_Gateway_az2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Nat Gateway Routing priv 1
resource "aws_route" "priv_sub_route1" {
  route_table_id            = aws_route_table.private_route_tableA.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gateway_az1.id
  }

  # Nat Gateway Routing priv 2
resource "aws_route" "priv_sub_route2" {
  route_table_id            = aws_route_table.private_route_tableA.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gateway_az2.id
  }

#ec2 in public Subnet
 resource "aws_instance" "pub_instance" {
  ami                     = var.pub_ami
  instance_type           = var.pub_instance_type
  count                   = var.pub_count
  subnet_id               = aws_subnet.web_pub_sub1.id
  vpc_security_group_ids = [aws_security_group.ssh_http.id]

  tags = {
    Name                  = "web-pub-server-${count.index+1}"
  }
}

#ec2 in private Subnet
 resource "aws_instance" "priv_instance" {
  ami                     = var.priv_ami
  instance_type           = var.priv_instance_type
  count                   = var.priv_count
  subnet_id               = aws_subnet.app_priv_sub1.id
  vpc_security_group_ids = [aws_security_group.ssh_http.id]

  tags = {
    Name                  = "app-priv-server-${count.index+1}"
  }
}

#Create Security Groups(SG)
resource "aws_security_group" "ssh_http" {
  name        = "allow_ssh_connection"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.Rock_Ltd.id

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }

 ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  tags = {
    Name = "allow ssh_http"
  }
}

#aws db subnet Group
resource "aws_db_subnet_group" "bbc_rds_group" {
  name       = "bbc_rds_group"
  subnet_ids = [aws_subnet.app_priv_sub1.id, aws_subnet.app_priv_sub2.id]

  tags = {
    Name = "bbc_rds_group"
  }
}


#Create RDS
resource "aws_db_instance" "bbc" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  port = 3306
  vpc_security_group_ids = [aws_security_group.ssh_http.id]
  db_subnet_group_name = aws_db_subnet_group.bbc_rds_group.name
}

