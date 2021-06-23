variable "aws_ami" {
  description = "defaut OpenSUSE 15.2"
  default     = "ami-0fde50fcbcd46f2f7"
}

variable "aws_instance_type" {
  description = "Machine Type"
  default     = "t2.xlarge"
}

variable "aws_worker" {
  default = 3 
}

variable "aws_master" {
  default = 1 
}

