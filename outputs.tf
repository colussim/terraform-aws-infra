output "ec2_machines" {
  value = aws_instance.worker-nodes.*.public_ip   
}

output "instance_ips" {
  value = aws_instance.master-nodes.*.public_ip
}
