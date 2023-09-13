resource "aws_docdb_subnet_group" "default" {
  name       = "${var.env}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-docdb-subnet-group" }
  )
}

resource "aws_security_group" "docdb" {
  name        = "${var.env}-docdb-security-group"
  description = "${var.env}-docdb-security-group"
  vpc_id      = var.vpc_id

  ingress {
    description      = "MongoDB"
    from_port        = 27017
    to_port          = 27017
    protocol         = "tcp"
    cidr_blocks      = var.allow_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-docdb-security-group" }
  )
}

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "${var.env}-docdb-cluster"
  engine                  =
  engine_version          = var.engine_version
  master_username         = data.aws_ssm_parameter.DB_ADMIN_USER.value
  master_password         = data.aws_ssm_parameter.DB_ADMIN_PASS.value
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.docdb.id]
#  storage_encrypted       = true
#  kms_key_id              = data.aws_kms_key.key.arn

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-docdb-cluster" }
  )
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.number_of_instances
  identifier         = "${var.env}-docdb-cluster-instances-${count.index+1}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = var.instance_class
#  storage_encrypted  = true
#  kms_key_id         = data.aws_kms_key.key.arn
}
