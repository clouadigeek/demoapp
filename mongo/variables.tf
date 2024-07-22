# name = "vpc-dev"
#   cidr = "10.0.0.0/16"   
#   private_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
#   public_subnets (Mongo)     = ["10.0.101.0/24"]

# Pick a Amazon AMI
#  aws ec2 describe-images --owners amazon --filters
#  "Name=name,Values=amzn-ami-*" "Name=root-device-type,Values=ebs" "Name=state,Values=available"
#   --query 'sort_by(Images,&CreationDate)[].[CreationDate,ImageId,Name]' --output text --region us-east-1

variable "region" {
    type = string
    default = "us-east-1"
}
variable "vpc_cidr" {
    type = string
    default =  "10.0.0.0/16"
}
variable "project_name" {
    type = string
    default =  "wizdemo"
}

variable "environment" {
    type = string
    default = "dev"
}

variable "mongo_az_cidr_block" {
    type = string
    default =  "10.0.1.0/24"
}

# Use an old out of cupport AMI
variable "mongo_ec2_ami" {
    type = string
    default =  "ami-06e07b42f153830d8"
}

variable "mongo_ec2_instance_type" {
    type = string
    default =  "t2.micro"
}

variable "mongo_ec2_instance_count" {
    type = number
    default =  1
}


