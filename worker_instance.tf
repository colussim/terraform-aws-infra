

resource "aws_instance" "worker-nodes" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = "admin"
  count =  var.aws_worker

   subnet_id = "${aws_subnet.vmtest-a.id}"
  security_groups = [
    "${aws_security_group.sg_infra.id}"
  ]



  tags = {
        Name = "worker-node-${count.index}"
    }
}
