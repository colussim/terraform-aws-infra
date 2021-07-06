resource "aws_security_group" "sg_infra" {
 name = "sg_infra"
 description = "standard ssh &amp; monitoring"
 vpc_id = "${aws_vpc.vpc01.id}"
  
 ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
 ingress {
   from_port = -1
   to_port = -1
   protocol = "icmp"
   cidr_blocks = ["0.0.0.0/0"]
 }
 egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
 }
}
