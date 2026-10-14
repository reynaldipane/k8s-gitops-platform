data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical, the publisher of Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "ssm_test" {
  name        = "${var.project_name}-ssm-test"
  description = "SSM test instance: no inbound, all outbound"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-ssm-test"
  }
}

resource "aws_vpc_security_group_egress_rule" "ssm_test_all" {
  security_group_id = aws_security_group.ssm_test.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols, all ports
}

resource "aws_instance" "ssm_test" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private["a"].id
  iam_instance_profile   = aws_iam_instance_profile.node.name
  vpc_security_group_ids = [aws_security_group.ssm_test.id]

  tags = {
    Name = "${var.project_name}-ssm-test"
  }
}