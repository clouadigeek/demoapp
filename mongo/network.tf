# Creating VPC
resource "aws_vpc" "demovpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"
tags = {
   Name = "${var.project_name}-${var.environment}-vpc"
  }
}
# Creating Internet Gateway
resource "aws_internet_gateway" "mongo_igw" {
  vpc_id = "${aws_vpc.demovpc.id}"
tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}
# Creating Route Table
resource "aws_route_table" "mongo_rt" {
  vpc_id = "${aws_vpc.demovpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mongo_igw.id}"
    
  }
tags = {
    Name = "${var.project_name}-${var.environment}-route"
  }
}
# Associating Route Table
resource "aws_route_table_association" "mongo_rt_asc" {
  subnet_id      = "${aws_subnet.mongo_subnet.id}"
  route_table_id = "${aws_route_table.mongo_rt.id}"
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

################################################################################
#Create Public Subnets, Route Table and Add Public Route
################################################################################

# create public subnet Mongo
resource "aws_subnet" "mongo_subnet" {
  vpc_id                  = aws_vpc.demovpc.id
  cidr_block              = var.mongo_az_cidr_block
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-mongo-az"
  }
}

# Creating Security Group
resource "aws_security_group" "mongo_sg" {
  name        = "mongo_sec"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.demovpc.id}"

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # MongoDB access from anywhere
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-mongo-sg"
  }
}



# resource "aws_s3_bucket_policy" "mongo_backup_bucket_policy" {
#   bucket = aws_s3_bucket.mongo_backup.id
#   policy = data.aws_iam_policy_document.mongo_backup_bucket_policy.json
# }

# Add multiple policies to ec2 instance profile
# # Define the IAM role
# resource "aws_iam_role" "mongo_role" {
#   name               = "mongo-role"
#   assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
# }

# # Define the trust policy for EC2 to assume the role
# data "aws_iam_policy_document" "ec2_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# # Define the first policy to be attached to the role
# data "aws_iam_policy_document" "mongo_policy_1" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#       "s3:DeleteObject"
#     ]
#     resources = ["arn:aws:s3:::${aws_s3_bucket.mongo_backup.id}/*"]
#   }
# }

# # Define the second policy to be attached to the role
# data "aws_iam_policy_document" "mongo_policy_2" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "dynamodb:GetItem",
#       "dynamodb:PutItem",
#       "dynamodb:UpdateItem"
#     ]
#     resources = ["arn:aws:dynamodb:*:*:table/my-table"]
#   }
# }

# Attach the first policy to the role
# resource "aws_iam_role_policy" "mongo_policy_1" {
#   name   = "mongo-policy-1"
#   role   = aws_iam_role.mongo_role.id
#   policy = data.aws_iam_policy_document.mongo_policy_1.json
# }

# # Attach the second policy to the role
# resource "aws_iam_role_policy" "mongo_policy_2" {
#   name   = "mongo-policy-2"
#   role   = aws_iam_role.mongo_role.id
#   policy = data.aws_iam_policy_document.mongo_policy_2.json
# }

# # Create the instance profile and associate it with the role
# resource "aws_iam_instance_profile" "mongo_instance_profile" {
#   name = "mongo-instance-profile"
#   role = aws_iam_role.mongo_role.name
# }



