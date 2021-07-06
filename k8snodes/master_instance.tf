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

  sudo wget https://raw.githubusercontent.com/colussim/terraform-aws-infra/main/k8sconf/setk8sconfig.yaml -O /tmp/setk8sconfig.yaml
  sudo /usr/bin/kubeadm init --config /tmp/setk8sconfig.yaml

mkdir -p $HOME/.kube && sudo /bin/cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

/usr/bin/kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')
/usr/bin/kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended.yaml
/usr/bin/kubectl apply -f https://raw.githubusercontent.com/colussim/terraform-aws-infra/main/k8sconf/clusteradmin.yaml


EOH
]
connection {
                type        = "ssh"
                user        = "ec2-user"
                host     = aws_instance.master-nodes.public_ip
                private_key = file(var.private_key)
        }
}
provisioner "local-exec" {
      command    = "./k8sconf/getkubectl-conf.sh ${self.public_ip}"
  }

  tags= {
        Name = "master-node-0"
    }
}

data "external" "kubeadm_join" {
  program = ["./k8sconf/kubeadm-token.sh"]

  query = {
    host = aws_instance.master-nodes.public_ip
  }
  depends_on = [aws_instance.master-nodes]

}
