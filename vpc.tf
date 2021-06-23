variable "region" { default = "us-east-1" }

resource "aws_vpc" "vpc01" {
 cidr_block = "10.1.0.0/16"
 enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "vmtest-a" {
 vpc_id = "${aws_vpc.vpc01.id}"
 cidr_block = "10.1.0.0/23"
 availability_zone = "${var.region}a"
 map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw-to-internet01" {
 vpc_id = "${aws_vpc.vpc01.id}"
}
  
resource "aws_route_table" "route-to-gw01" {
 vpc_id = "${aws_vpc.vpc01.id}"
 route {
 cidr_block = "0.0.0.0/0"
   gateway_id = "${aws_internet_gateway.gw-to-internet01.id}"
 }
}
resource "aws_route_table_association" "vmtest-a" {
 subnet_id = "${aws_subnet.vmtest-a.id}"
 route_table_id = "${aws_route_table.route-to-gw01.id}"
}


