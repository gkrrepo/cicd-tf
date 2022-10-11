resource "aws_vpc" "main" {                            #creation of VPC main
  cidr_block       = "${var.cidr}"
  instance_tenancy = "${var.tenancytype}"
  enable_dns_support   = "${var.dnsSupport}"
  enable_dns_hostnames = "${var.dnsHostNames}"

  tags = {
    Name = "main"
  }
}
resource "aws_subnet" "pub-subnets" {                   #creation of public subnet in VPC main
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${var.pubsubaz}"
  cidr_block              = "${var.pubsubcidr}"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-subnets"
  }
}

resource "aws_internet_gateway" "i-gateway" {             #creation of internet gateway for VPC main
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "igtw"
  }
}

resource "aws_route_table" "pub-table" {                  #creation of public route table for public subnet
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "pub-route" {                         #associate public route table with internet gateway
  route_table_id         = "${aws_route_table.pub-table.id}"
  destination_cidr_block = "${var.acceptallcidr}"
  gateway_id             = "${aws_internet_gateway.i-gateway.id}"
}

resource "aws_route_table_association" "as-pub" {          # associate public subnet with public route table
  route_table_id = "${aws_route_table.pub-table.id}"
  subnet_id      = "${aws_subnet.pub-subnets.id}"
}

resource "aws_security_group" "publicsg" {                #creation of public security group for public subnet
  name        = "public security group"
  description = "Allows inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "enable SSH"
    from_port        = 22
    to_port          = 22
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
    Name = "publicsg"
  }
}

resource "aws_security_group" "privatesg" {        #creation of private security group for private subnet
  name        = "private security group"
  description = "private security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "privatesg"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups  = ["${aws_security_group.publicsg.id}"]
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "privatesg"
  }
}
resource "aws_instance" "public" {                        #creation of public instance
  ami           = "${var.amiid}"
  instance_type = "${var.instancetype}"
  subnet_id = "${aws_subnet.pub-subnets.id}"
  vpc_security_group_ids = ["${aws_security_group.publicsg.id}"] 
  key_name = "${var.key_name}"

  tags = {
    Name = "public_instance"
  }
}
