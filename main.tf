resource "aws_iam_role" "role" {
  name = "${var.env}-$(var.component)-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-$(var.component)-role" }
  )
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.env}-$(var.component)-role"
  role = aws_iam_role.role.name
}

resource "aws_iam_policy" "policy" {
  name        = "${var.env}-$(var.component)-parameter-store-policy"
  path        = "/"
  description = "${var.env}-$(var.component)-parameter-store-policy"

  policy = jsondecode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:us-east-1:633788536644:parameter/${var.env}.${var.component}*",
          "arn:aws:ssm:us-east-1:633788536644:parameter/nexus*",
          "arn:aws:ssm:us-east-1:633788536644:parameter/$(var.env).docdb*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_security_group" "main" {
  name        = "${var.env}-$(var.component)-security-group"
  description = "${var.env}-$(var.component)-security-group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.allow_cidr

  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-$(var.component)-security-group" }
  )
}



resource "aws_launch_template" "main" {
  name   = "${var.env}-$(var.component)-template"
  image_id      = data.aws_ami.centos8.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data = base64decode(templatefile("${path.module}/user-data.sh", {component = var.component, env= var.env}))

  iam_instance_profile {
    arn = aws_iam_instance_profile.profile.arn
  }

  instance_market_options {
    market_type = "spot"
  }
}




