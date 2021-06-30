## Our first AWS infrastructure since Terraform

The purpose of this tutorial is to create 4 identical OpenSuse LEAP 15.3 virtual machines in AWS that we will deploy only with Terraform.
With the goal of using this infrastrucutre to deploy a kubernetes cluster .

## Architecture

We will create 4 VMs :
  - master-node-0
  - worker-node-0
  - worker-node-1
  - worker-node-2

![AWS infra, AWS infra](/images/awsinfra.png)


## Prerequisites

Before you get started, you’ll need to have these things:
* Terraform > 0.13.x
* kubectl installed on the compute that hosts terraform
* An AWS account with the IAM permissions
* AWS CLI : [the AWS CLI Documentation](https://github.com/aws/aws-cli/tree/v2){:target="_blank" }


Take a closer look at the Terraform configuration files.

We have a first file **main.tf** with the following content. This file will contain general information about Terraform and its relationship with AWS:
```
provider "aws" {
region = "us-east-1"
shared_credentials_file = "~/.aws/credentials"
```

Let's detail the contents of this file:
```
- **provider** : this directive defines the provider with which terraform will interact. This is aws.
- **region** : the name of the default region
- **shared_credentials_file** : your own AWS credentials defined in the first step
```

The file **vpc.tf** which contains the information of our virtual private cloud (vpc), namely a logical and independent organization of our infrastructure in the AWS cloud.

We will define a VPC and its Subnet and then define the routing table for the VPC

```

## Define a VPC
variable "region" { default = "us-east-1" }

resource "aws_vpc" "vpc01" {
 cidr_block = "10.1.0.0/16"
 enable_dns_support   = true
  enable_dns_hostnames = true
}

## Define a Subnet
resource "aws_subnet" "vmtest-a" {
 vpc_id = "${aws_vpc.vpc01.id}"
 cidr_block = "10.1.0.0/23"
 availability_zone = "${var.region}a"
 map_public_ip_on_launch = true
}

## Define the routing table for the VPC
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
```

In the **security.tf** file we will define the security rule to allow ssh access only from some specific ips (for security reasons) and allow the vm to access anywhere:

```
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

- **vpc_id** : defines which vpc this security group belongs to.
- **ingress** : will define the inbound flows to the resources that belong to this security group, in this article our instance.
- **from_port** : for the source port, here 22 to allow SSH.
- **to_port** : for the destination port, here 22 to allow SSH.
- **protocol** : for the protocol type of the stream.
- **cidr_blocks** : indicates a list of accepted input addresses. This is the address of my office.
- **egress** : will define the outgoing flows of the resources attached to our security group.
- **from_port** : for the source port. Here 0 because we will allow everything.
- **to_port** : for the destination port. Here 0 because we will allow everything.
- **protocol** : for the protocol type. Here a special case with a value of -1 because we allow all types of output streams.
- **cidr_blocks** : for the destination addresses. Here 0.0.0.0/0 to allow everything.

```

In the **master_instence.tf**  and **worker_instance** files we will define the description of our instances :

**master_instance.tf** file :

```
resource "aws_key_pair" "admin" {
   key_name   = "admin"
   public_key = "ssh-rsa xxxxxxx"
 }


resource "aws_instance" "master-nodes" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = "admin"
  
  subnet_id = "${aws_subnet.vmtest-a.id}"
  security_groups = [
    "${aws_security_group.sg_infra.id}"
  ]

  tags = {
        Name = "master-node-0"
    }
}
```
**worker_instance.tf** file :

```
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
```

This **master_instance** file contains two blocks of code starting with the resource keyword. Let's detail the first block of code in this file :

- **resource** : this keyword indicates that we will define a resource, which is the basic unit of Terraform. Here it is of type aws_key_pair, defining a key pair to use to connect to our EC2 instances.
- **key_name** : the name of the key pair, which we will use to identify it in other resources.
- **public_key**: the SSH public key, which will be deposited in your instances, allowing the connection via SSH.

Let's now detail the second resource of the file which is identical in worker_instance file.

- **resource** : contains a resource of type aws_instance named "master-nodes" or "worker-nodes".
- **ami** : the ami indicated here is the official image of the Suse Linux Enterprise 15.2 distribution for the chosen region (it varies according to the region).
- **instance_type** : the AWS instance type, which defines the performance of the virtual machine, here a very modest template.
- **key_name** : the name of the key pair to SSH into the instance, defined by the previous resource.
- **count** : The count meta-argument accepts a whole number, and creates that many instances of the resource or module. (only use in worker_instance)
- **subnet_id** : the subnet of the instance defined in the **vpc.tf** file
- **security_groups** : the security group defined in the **security.tf** file

In the file **variables.tf** we will define the default values for the instances:

- the instance type
- the number of instances worker
- the number of master instances


In the file **outpu.tf** fwe will define the variables which are shared between the modules
```
output "worker_public_ip" {
  value = aws_instance.worker-nodes.*.public_ip
}

output "master_public_ip" {
  value = aws_instance.master-nodes.public_ip
}
```
## Usage

Let's deploy our infrastructure :

Use terraform init command in terminal to initialize terraform and download the configuration files.
```
terraform-aws-infra:>$ terraform init
```

```
terraform-aws-infra:>$ terraform apply
aws_key_pair.admin: Creating...
aws_vpc.vpc01: Creating...
aws_key_pair.admin: Creation complete after 1s [id=admin]
aws_vpc.vpc01: Still creating... [10s elapsed]
aws_vpc.vpc01: Creation complete after 18s [id=vpc-064ad92334ace1044]
aws_internet_gateway.gw-to-internet01: Creating...
aws_subnet.vmtest-a: Creating...
aws_security_group.sg_infra: Creating...
aws_internet_gateway.gw-to-internet01: Creation complete after 3s [id=igw-0d42dfe99486bcd75]
aws_route_table.route-to-gw01: Creating...
aws_security_group.sg_infra: Creation complete after 5s [id=sg-0d890f302629ec4b3]
aws_route_table.route-to-gw01: Creation complete after 2s [id=rtb-0313eefe1abb16a03]
aws_subnet.vmtest-a: Still creating... [10s elapsed]
aws_subnet.vmtest-a: Creation complete after 13s [id=subnet-0f0993185ee216270]
aws_instance.worker-nodes[1]: Creating...
aws_instance.worker-nodes[0]: Creating...
aws_instance.worker-nodes[2]: Creating...
aws_route_table_association.vmtest-a: Creating...
aws_instance.master-nodes[0]: Creating...
aws_route_table_association.vmtest-a: Creation complete after 1s [id=rtbassoc-095b8d604fd18b4b0]
aws_instance.master-nodes[0]: Still creating... [10s elapsed]
aws_instance.worker-nodes[1]: Still creating... [10s elapsed]
aws_instance.worker-nodes[2]: Still creating... [10s elapsed]
aws_instance.worker-nodes[0]: Still creating... [10s elapsed]
aws_instance.master-nodes[0]: Still creating... [20s elapsed]
aws_instance.worker-nodes[2]: Still creating... [20s elapsed]
aws_instance.worker-nodes[1]: Still creating... [20s elapsed]
aws_instance.worker-nodes[0]: Still creating... [20s elapsed]
aws_instance.worker-nodes[0]: Creation complete after 20s [id=i-0402c9120538c601b]
aws_instance.worker-nodes[2]: Creation complete after 21s [id=i-0875cb2fd738ba495]
aws_instance.master-nodes[0]: Creation complete after 21s [id=i-0491b675f4ffcc234]
aws_instance.worker-nodes[1]: Creation complete after 21s [id=i-02965632c8c919f17]

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.
terraform-aws-infra:>
```

After a few minutes our instances are up running

Tear down the whole Terraform plan with :

```
terraform-aws-infra:>$ terraform destroy -force
```
## Conclusion

With Terraform, it easy and fast it is to create an AWS Virtual Machines infrastructure.  
Terraform is one of the most popular Infrastructure-as-code (IaC) tool used by DevOps teams to automate infrastructure tasks. It is used to automate the provisioning of your cloud resources.. It is currently the best tool to automate your infrastructure creation.
It supports multiple providers such as AWS, Azure, Oracle, GCP, and many more.

## Resources :

[Documentation, the Terraform Documentation](https://www.terraform.io/docs/index.html "the Terraform Documentation")

[Documentation, AWS Build Infrastructure](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started "AWS Build Infrastructure")

[Documentation, the AWS CLI](https://github.com/aws/aws-cli/tree/v2 "the AWS CLI")

Next step , see details [here](https://techlabnews.com/2021/terraform-AWS-infra/ "Our first AWS infrastructure since Terraform")

