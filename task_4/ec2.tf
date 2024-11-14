data "aws_security_group" "public_sg_jenkins" {
  name = aws_security_group.public_sg_jenkins.name
}

resource "aws_instance" "public_instance_jenkins" {
  ami                         = "ami-0866a3c8686eaeeba"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public_subnet_jenkins.id
  key_name                    = "jenkins-setup"
  associate_public_ip_address = true
  security_groups             = [data.aws_security_group.public_sg_jenkins.id]
  vpc_security_group_ids      = [aws_security_group.public_sg_jenkins.id]
  availability_zone           = var.availability_zones[0]


  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname "master-k3s"
              # install k3s
              curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.21.3+k3s1 sh -s - server --token=${random_password.k3s_token.result}
              sleep 30  # wait K3s start
              export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              # sudo chmod 644 /etc/rancher/k3s/k3s.yaml
              # Set KUBECONFIG variable
              sudo su -c 'echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc'
              source ~/.bashrc
              # install Helm
              curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
              # install Nginx
              echo "install Nginx"
              helm repo add bitnami https://charts.bitnami.com/bitnami
              helm install my-nginx bitnami/nginx
              # Check and after uninstall Nginx
              echo "Check and after uninstall Nginx"
              kubectl get pods --namespace default
              helm uninstall my-nginx --namespace default
              kubectl get pods --namespace default
              # install Jenkins
              kubectl create namespace jenkins
              sudo mkdir /data/jenkins -p
              sudo chown -R 1000:1000 /data/jenkins
              wget https://raw.githubusercontent.com/viktordavidovich/rsschool-devops-course-ci/refs/heads/task_4/task_4/jenkins/jenkins-volume.yaml
              kubectl apply -f jenkins-volume.yaml
              sudo mkdir -p /data/jenkins-volume/
              sudo chown -R 1000:1000 /data/jenkins-volume/
              kubectl get pv
              kubectl get storageclass
              wget https://raw.githubusercontent.com/viktordavidovich/rsschool-devops-course-ci/refs/heads/task_4/task_4/jenkins/jenkins-sa.yaml
              kubectl apply -f jenkins-sa.yaml
              wget https://raw.githubusercontent.com/viktordavidovich/rsschool-devops-course-ci/refs/heads/task_4/task_4/jenkins/jenkins-values.yaml
              helm repo add jenkinsci https://charts.jenkins.io
              helm repo update
              helm search repo jenkinsci
              chart=jenkinsci/jenkins
              helm install jenkins -n jenkins -f jenkins-values.yaml $chart
              sleep 30
              mkdir -p /root/conf
              sudo ln -s /opt/Jenkins/conf /root/conf
              # Retrieve the Jenkins admin password and save to a file
              jsonpath="{.data.jenkins-admin-password}"
              secret=$(kubectl get secret -n jenkins jenkins -o jsonpath="$jsonpath")
              echo "$secret" | base64 --decode > /root/conf/jenkins.txt
              sudo cat /root/conf/jenkins.txt
              JENKINS_URL="http://localhost:32000"
              JENKINS_USER="admin"
              JENKINS_PASS=$(cat /root/conf/jenkins.txt)
              echo cat /root/conf/jenkins.txt
              EOF

  user_data_replace_on_change = true
  tags = {
    Name = "public_instance_jenkins"
  }
}

