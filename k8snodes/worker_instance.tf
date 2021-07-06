

resource "aws_instance" "worker-nodes" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = "admin"
  count =  var.aws_worker

   subnet_id = "${aws_subnet.vmtest-a.id}"
  security_groups = [
    "${aws_security_group.sg_infra.id}"
  ]
  provisioner "remote-exec" {
  inline = [
  <<EOH

  set -x
  sudo /usr/sbin/swapoff -a
  sleep 60

  sudo wget https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64.tar.gz -O - | sudo tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

  sudo modprobe overlay
  sudo modprobe br_netfilter
  sudo  sh -c 'echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf'
  sudo  sh -c 'echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf'
  sudo  sh -c 'echo net.ipv4.conf.all.forwarding=1 >> /etc/sysctl.conf'
  sudo  sh -c 'echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.conf'
  sudo sysctl -p

  sudo zypper addrepo https://download.opensuse.org/repositories/home:so_it_team/openSUSE_Leap_15.3/home:so_it_team.repo
  sudo sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/zypp/repos.d/home_so_it_team.repo
  sudo zypper install -y cri-o cri-tools
  sudo zypper install -y kubernetes1.20-client
  sudo zypper install -y podman
  sudo zypper rm -y docker
  sudo systemctl start crio
  sudo systemctl enable kubelet
  sudo systemctl start kubelet
  sudo systemctl daemon-reload

  sudo ${data.external.kubeadm_join.result.command}
  mkdir -p $HOME/.kube


EOH
]
connection {
                type        = "ssh"
                user        = "ec2-user"
                host     = "${self.public_ip}"
                private_key = file(var.private_key)
        }
}
provisioner "local-exec" {
      command    = "./k8sconf/setkubectl.sh ${self.public_ip}"
  }


  tags = {
        Name = "worker-node-${count.index}"
    }
}
