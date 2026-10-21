# All Nodes
resource "aws_security_group" "node" {
  name        = "${var.project_name}-node"
  description = "Kubernetes nodes: node-to-node traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-node"
  }
}

resource "aws_vpc_security_group_ingress_rule" "node_kubelet" {
  security_group_id            = aws_security_group.node.id
  description                  = "kubelet API (logs, exec, metrics-server)"
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
}

resource "aws_vpc_security_group_ingress_rule" "node_calico_vxlan" {
  security_group_id            = aws_security_group.node.id
  description                  = "Calico VXLAN (pod-to-pod)"
  referenced_security_group_id = aws_security_group.node.id

  ip_protocol = "udp"
  from_port   = 4789
  to_port     = 4789
}

resource "aws_vpc_security_group_ingress_rule" "node_calico_typha" {
  security_group_id            = aws_security_group.node.id
  description                  = "Calico Typha"
  referenced_security_group_id = aws_security_group.node.id

  ip_protocol = "tcp"
  from_port   = 5473
  to_port     = 5473
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.node.id
  description       = "All outbound (NAT, SSM, other nodes)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Control Plane Only
resource "aws_security_group" "control_plane" {
  name        = "${var.project_name}-control-plane"
  description = "Kubernetes control plane: API server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "{$var.project_name}-control-plane"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_api" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kube-apiserver from nodes"
  referenced_security_group_id = aws_security_group.control_plane.id

  ip_protocol = "tcp"
  from_port   = 6443
  to_port     = 6443
}