resource "aws_instance" "web" {
  ami           = "ami-0a699202e5027c10d"
  instance_type = "t2.micro"
  # Attach the security group defined below to the ec2 instace
  vpc_security_group_ids = [aws_security_group.TF_SG.id]
  #count = 2
  tags = {
    Name = "HelloWorld"
  }

  #USERDATA in AWS EC2 using Terraform
  user_data = file("script.sh")
}

# Create Security Group using Terraform

resource "aws_security_group" "TF_SG" {
  name        = "Security Group using Terraform"
  description = "Security Group using Terraform"
  vpc_id      = "vpc-0a638ed1fcf9d1fe6"

  tags = {
    Name = "TF_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "HTTPS_IP4" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "HTTPS_IP6" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "HTTP_IP4" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "HTTP_IP6" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "SSH_IP4" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "SSH_IP6" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.TF_SG.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}