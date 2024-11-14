data "aws_security_group" "public_sg_jenkins" {
  name = aws_security_group.public_sg_jenkins.name
}

resource "aws_instance" "public_instance_jenkins" {
  ami                         = "ami-0866a3c8686eaeeba"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public_subnet_jenkins.id
  key_name                    = "rsschool-learning-key"
  associate_public_ip_address = true
  security_groups             = [data.aws_security_group.public_sg_jenkins.id]
  vpc_security_group_ids      = [aws_security_group.public_sg_jenkins.id]
  availability_zone           = var.availability_zones[0]


  user_data = <<-EOF
              #!/bin/bash

              # ===== System Setup =====
              sudo apt-get update -y
              sudo apt-get install -y curl
              sudo ufw disable
              hostnamectl set-hostname "master-k3s"

              # ===== SSH Key Setup =====
              # Set up SSH key for the 'ubuntu' user
              mkdir -p /home/ubuntu/.ssh
              echo "${var.private_key}" > /home/ubuntu/.ssh/jenkins-setup.pem
              chmod 400 /home/ubuntu/.ssh/jenkins-setup.pem
              chown ubuntu:ubuntu /home/ubuntu/.ssh/jenkins-setup.pem

              # ===== K3s Installation and Configuration =====
              # Install k3s
              curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.21.3+k3s1 sh -s - server --token=${random_password.k3s_token.result}
              sleep 30  # wait for K3s to start
              export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              sudo chmod 644 /etc/rancher/k3s/k3s.yaml
              # Set KUBECONFIG variable for root user
              sudo su -c 'echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc'
              source ~/.bashrc

              # ===== Helm Installation =====
              curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

              # ===== Nginx Installation =====
              echo "Installing Nginx using Helm"
              helm repo add bitnami https://charts.bitnami.com/bitnami
              helm install my-nginx bitnami/nginx
              echo "Verifying Nginx installation"
              kubectl get pods --namespace default
              echo "Uninstalling Nginx"
              helm uninstall my-nginx --namespace default
              kubectl get pods --namespace default

              # ===== Jenkins Installation =====
              kubectl create namespace jenkins
              # Create persistent volumes
              sudo mkdir -p /data/jenkins /data/jenkins-volume
              sudo chown -R 1000:1000 /data/jenkins /data/jenkins-volume
              wget https://raw.githubusercontent.com/viktordavidovich/rsschool-devops-course-ci/refs/heads/task_4/jenkins/jenkins-volume.yaml
              kubectl apply -f jenkins-volume.yaml
              kubectl get pv
              kubectl get storageclass

              # Set up service account for Jenkins
              wget https://raw.githubusercontent.com/jenkins-infra/jenkins.io/master/content/doc/tutorials/kubernetes/installing-jenkins-on-kubernetes/jenkins-sa.yaml
              kubectl apply -f jenkins-sa.yaml

              # Install Jenkins using Helm
              wget https://raw.githubusercontent.com/viktordavidovich/rsschool-devops-course-ci/refs/heads/task_4/jenkins/jenkins-values.yaml
              helm repo add jenkinsci https://charts.jenkins.io
              helm repo update
              helm search repo jenkinsci
              chart=jenkinsci/jenkins
              helm install jenkins -n jenkins -f jenkins-values.yaml $chart
              sleep 30

              # Retrieve Jenkins admin password and save to a file
              mkdir -p /root/conf
              jsonpath="{.data.jenkins-admin-password}"
              secret=$(kubectl get secret -n jenkins jenkins -o jsonpath="$jsonpath")
              echo "$secret" | base64 --decode > /root/conf/jenkins.txt
              sudo cat /root/conf/jenkins.txt

              # Setup Jenkins access details
              JENKINS_URL="http://localhost:32000"
              JENKINS_USER="admin"
              JENKINS_PASS=$(cat /root/conf/jenkins.txt)
              echo "Jenkins admin password is stored in /root/conf/jenkins.txt"

              EOF

  user_data_replace_on_change = true
  tags = {
    Name = "public_instance_jenkins"
  }
}

