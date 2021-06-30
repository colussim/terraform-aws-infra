variable "aws_ami" {
  description = "defautOpenSUSE LEAP 15.3"
  default     = "ami-0c8fcb221ea2d85f6"
}

variable "aws_instance_type" {
  description = "Machine Type"
  default     = "t2.xlarge"
}

variable "aws_worker" {
  default = 3 
}

