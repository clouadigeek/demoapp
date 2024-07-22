# Create ebs volume
resource "aws_ebs_volume" "mongo_ebs" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  size              = 25
  encrypted         = true
tags = {
    Name = "${var.project_name}-${var.environment}-mongo-ebs"
  }
}

# Mongo S3 bucket bcakup
resource "aws_s3_bucket" "mongo_backup" {
  bucket = "${var.project_name}-${var.environment}-mongo"
  # acl    = "public-read-write"
  force_destroy = true
  tags = {
    Name   = "${var.project_name}-${var.environment}-mongo-s3"
  }
}


resource "aws_s3_bucket_public_access_block" "public_bucket_access_block" {
  bucket = aws_s3_bucket.mongo_backup.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_bucket_policy" {
  bucket = aws_s3_bucket.mongo_backup.id
  policy = data.aws_iam_policy_document.public_bucket_policy.json
}

data "aws_iam_policy_document" "public_bucket_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mongo_backup.id}",
      "arn:aws:s3:::${aws_s3_bucket.mongo_backup.id}/*"
    ]
  }
}


# EC2 assume role policy
data "aws_iam_policy_document" "mongo_ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EC2 IAM policy document
data "aws_iam_policy_document" "mongo_ec2_iam_policy" {
  statement {
    effect = "Allow"
    actions = [
     "*"
    ]
    resources = ["*"]
  }
}

# EC2 IAM role
resource "aws_iam_role" "mongo_ec2_iam_role" {
  name = "mongo-ec2-iam-role"
  assume_role_policy = data.aws_iam_policy_document.mongo_ec2_assume_role_policy.json
  inline_policy {
    name = "AccountAdmin"
    policy = data.aws_iam_policy_document.mongo_ec2_iam_policy.json
  }
}

# EC2 IAM instance profile
resource "aws_iam_instance_profile" "mongo_ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.mongo_ec2_iam_role.name
}

# Creating EC2 instance
resource "aws_instance" "mongo_ec2" {
  ami           = "${var.mongo_ec2_ami}"
  instance_type = "${var.mongo_ec2_instance_type}"
  count         =  var.mongo_ec2_instance_count
  subnet_id     = "${aws_subnet.mongo_subnet.id}"
  security_groups = ["${aws_security_group.mongo_sg.id}"]
  iam_instance_profile = aws_iam_instance_profile.mongo_ec2_profile.name
  user_data = "${path.module}/scripts/mongodb.sh"
  # TBD
  key_name      = aws_key_pair.mongo_key_pair[count.index].key_name
  root_block_device {
    volume_size = 10
    encrypted   = false
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-mongo-ec2"
  }
}

# Attaching EBS Volume
resource "aws_volume_attachment" "mongo_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.mongo_ebs.id}"
  count       =  var.mongo_ec2_instance_count
  instance_id = "${aws_instance.mongo_ec2[count.index].id}"
}

# Generate unique TLS private keys for each instance
resource "tls_private_key" "mongo_key" {
  count = var.mongo_ec2_instance_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create unique key pairs in AWS for each instance
resource "aws_key_pair" "mongo_key_pair" {
  count = var.mongo_ec2_instance_count
  key_name   = "mongo-key-pair-${count.index}"
  public_key = tls_private_key.mongo_key[count.index].public_key_openssh
}

# Save the private keys to local files
resource "local_file" "private_key" {
  count = var.mongo_ec2_instance_count

  content  = tls_private_key.mongo_key[count.index].private_key_pem
  filename = "mongo-key-${count.index}.pem"
}

# Print the private keys in the output
output "private_key_pems" {
  value     = [for key in tls_private_key.mongo_key : key.private_key_pem]
  sensitive = true
}

