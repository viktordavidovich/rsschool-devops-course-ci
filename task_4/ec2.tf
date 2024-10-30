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
                sudo apt-get update -y
                sudo apt-get install -y curl
                sudo ufw disable

                # Set up SSH key for the 'ubuntu' user
                mkdir -p /home/ubuntu/.ssh
                echo "${var.private_key}" > /home/ubuntu/.ssh/rsschool-learning-key.pem
                chmod 400 /home/ubuntu/.ssh/rsschool-learning-key.pem
                chown ubuntu:ubuntu /home/ubuntu/.ssh/rsschool-learning-key.pem

                # Install k3s
                curl -sfL https://get.k3s.io | sh -
                sudo chmod 644 /etc/rancher/k3s/k3s.yaml
              EOF


  tags = {
    Name = "public_instance_jenkins"
  }
}

