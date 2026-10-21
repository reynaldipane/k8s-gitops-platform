data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

locals {
  # worker name => private subnet (AZ suffix)
  workers = {
    worker-1 = "a"
    worker-2 = "b"
  }
}

resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.node_instance_type
  subnet_id              = aws_subnet.private["a"].id
  iam_instance_profile   = aws_iam_instance_profile.node.name
  vpc_security_group_ids = [aws_security_group.node.id, aws_security_group.control_plane.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  # Boot only after the private subnets route to the NAT
  depends_on = [aws_route_table_association.private]

  tags = {
    Name = "${var.project_name}-control-plane"
  }
}

resource "aws_instance" "worker" {
  for_each = local.workers

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.node_instance_type
  subnet_id              = aws_subnet.private[each.value].id
  iam_instance_profile   = aws_iam_instance_profile.node.name
  vpc_security_group_ids = [aws_security_group.node.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  depends_on = [aws_route_table_association.private]

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}
