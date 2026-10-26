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

  join_parameter = "/${var.project_name}/join-command"

  node_prep = templatefile("${path.module}/../scripts/node-prep.sh.tftpl", {
    kube_minor = var.kube_minor
  })
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
  depends_on = [aws_route_table_association.private, aws_iam_role_policy_attachment.node_join_parameter]

  tags = {
    Name = "${var.project_name}-control-plane"
  }

  user_data = templatefile("${path.module}/../scripts/control-plane.sh.tftpl", {
    node_prep      = local.node_prep
    pod_cidr       = var.pod_cidr
    calico_version = var.calico_version
    aws_region     = var.aws_region
    join_parameter = local.join_parameter
  })

  user_data_replace_on_change = true
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

  user_data = templatefile("${path.module}/../scripts/worker.sh.tftpl", {
    node_prep      = local.node_prep
    aws_region     = var.aws_region
    join_parameter = local.join_parameter
  })

  user_data_replace_on_change = true
}
