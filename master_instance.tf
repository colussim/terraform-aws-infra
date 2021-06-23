resource "aws_key_pair" "admin" {
   key_name   = "admin"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+5EWMOoonqtDkqdCQwI1DLdjxbWap17h1zoEElZXKJn3Cencf+IQgNEKV2z0lo31in8xv+6wI8Xh/H+y0naiLF4nHkFvHUWnigaNIWGvDz11CE6lzXfQIZZYpRBzBBvDd/FYCdjPzeAnmL3nfUbXk18Oliz9KlMYKMMKZXC02J0h/Rvhua66M6/DkjJ5uHXubYct6HBNpUQI3+ThDgUeFW0duwba+mBjG9RNToZBJJSBmp8GSfZDyGZ6U4G/lzLEOi5H1XNx81STgBWmOUPppYcnfdZCm082UAxNyXa10kwh1Th4jcEJuGOMcyM2vnXYwWp4JdYsk+09nmK7NRbFOFpIqmXCrb6aYYsB84+3EPgn8GNmL53LDmXqwpB0bhy4TY2XtFnRfQp6Igx3fuRv6k+fz8cR3+MDn/jaJ6iZB4Pi9bvDTlcJAB/1WrJPcC0l8k59DOQg5deIZm8Oyb4+8osKakDfHjOby2ZE/ed5KKHEJ1GpCT89Wp0/4cUITL+c="
 }


resource "aws_instance" "master-nodes" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = "admin"
   subnet_id = "${aws_subnet.vmtest-a.id}"
  security_groups = [
    "${aws_security_group.sg_infra.id}"
  ]


  tags= {
        Name = "master-node-0"
    }
}
