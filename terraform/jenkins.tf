resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "jenkins" {
  ami           = "ami-03f4878755434977f" # Ubuntu 20.04 ap-south-1
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public[0].id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y openjdk-11-jdk curl gnupg

    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
    echo "deb https://pkg.jenkins.io/debian binary/" > /etc/apt/sources.list.d/jenkins.list

    apt update -y
    apt install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOF

  tags = { Name = "jenkins-server" }
}
