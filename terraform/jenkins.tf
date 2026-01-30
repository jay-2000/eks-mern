#############################################
# SECURITY GROUP FOR JENKINS
#############################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins UI"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

#############################################
# IAM INSTANCE PROFILE (already exists)
#############################################
# Uses: aws_iam_instance_profile.jenkins_profile

#############################################
# JENKINS EC2 INSTANCE (SYSTEMD INSTALL)
#############################################
resource "aws_instance" "jenkins" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 22.04 ap-south-1
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = var.jenkins_key

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/jenkins-userdata.log 2>&1

    echo "===== Jenkins installation started ====="

    apt-get update -y
    apt-get install -y \
      openjdk-17-jdk \
      curl \
      wget \
      gnupg \
      apt-transport-https \
      ca-certificates \
      software-properties-common \
      docker.io \
      unzip

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ubuntu

    # Jenkins GPG key (2023+)
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
      | gpg --dearmor \
      | tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
      | tee /etc/apt/sources.list.d/jenkins.list

    apt-get update -y
    apt-get install -y jenkins

    systemctl daemon-reload
    systemctl enable jenkins
    systemctl start jenkins

    # AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    echo "===== Jenkins installation completed ====="
  EOF

  tags = {
    Name = "Jenkins-Server"
  }
}


