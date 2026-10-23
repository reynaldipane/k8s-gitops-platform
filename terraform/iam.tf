data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.project_name}-node"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.project_name}-node"
  role = aws_iam_role.node.name
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "node_join_parameter" {
  statement {
    actions = ["ssm:PutParameter", "ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*",
    ]
  }
}

resource "aws_iam_role_policy" "node_join_parameter" {
  name   = "join-parameter"
  role   = aws_iam_role.node.id
  policy = data.aws_iam_policy_document.node_join_parameter.json
}