#############################################
# SECURITY GROUP FOR JENKINS
#############################################
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main.id

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
# JENKINS EC2 INSTANCE (AUTO INSTALL)
#############################################
resource "aws_instance" "jenkins" {
  ami                    = "ami-0ff91eb5c6fe7cc86"   # Valid Ubuntu 22.04 for ap-south-1
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = var.jenkins_key

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y openjdk-17-jdk docker.io apt-transport-https wget gnupg

    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null

    echo deb [signed-by=/usr/share-keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null

    apt update -y
    apt install -y jenkins

    systemctl start jenkins
    systemctl enable jenkins
  EOF

  tags = {
    Name = "Jenkins-Server"
  }
}
