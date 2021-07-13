variable "aws_ami" {
  description = "defaut OpenSUSE tumbleweed"
  default     = "ami-04ec8d1d72a81ee63"
}

variable "aws_instance_type" {
  description = "Machine Type"
  default     = "t3a.xlarge"
}

variable "aws_worker" {
  default = 3 
}

