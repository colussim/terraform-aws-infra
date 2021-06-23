output "worker_public_ip" {
  value = aws_instance.worker-nodes.*.public_ip
}

output "master_public_ip" {
  value = aws_instance.master-nodes.public_ip
}
