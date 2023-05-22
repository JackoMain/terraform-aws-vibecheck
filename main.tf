terraform {
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket            = "dellaters3"#used for storage
    key               = "terraform.tfstate"#state file here
    region            = "us-east-1"
    #dynamodb_table    = " "#create table, place name here. Used for locking
    encrypt           = "true"
  }
}

provider "aws" {
  region = var.region
}

#module "base" {
#  source  = "resinstack/base/consul"
#  version = "0.4.0"
#}



resource "aws_instance" "Indoram" {
  ami                 = var.ami # Linux/UNIX // us-east-1
  instance_type       = var.instance_type
  security_groups     = [aws_security_group.instances.name]
  user_data           = <<-EDF

                      EDF

  #tags = {
  #  name = "testinst"
  #}
}

resource "aws_instance" "Indoram2" {
  ami             = "ami-0c553fd621f67f9d7" # Linux/UNIX // us-east-1
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EDF

                  EDF

  #tags = {
  #  name = "testinst"
  #}
}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "woop"              #literally just the bucket's name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_config" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#aws lambda function
resource "aws_iam_role" "lambda_role" {   
  name   = "choose_yer_fighter"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

#IAM policy for lambda
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

#IAM policy attached to IAM role
#For lambda function
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {

type        = "zip"

source_dir  = "${path.module}/python/"

output_path = "${path.module}/python/fighterchose-python.zip"

}
 

resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = "${path.module}/python/fighterchose-python.zip"
  function_name                  = "Spacelift_Test_Lambda_Function"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "chooseyerfighter.lambda_handler"
  runtime                        = "python3.9"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

}

data "aws_vpc" "default_vpc" {
  default = true
}

resource "aws_security_group" "instances" {
  name = "Rammy-sec-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.instances.id
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"] #allows all ip addresses
}

#load balancer not added since the scope of project doesn't call for one
#it's not managing ec2's that have different content
#which is the same reason the "consul" module isn't used here

resource "aws_db_instance" "db_instance" {
  auto_minor_version_upgrade = false
  allocated_storage = 20
  storage_type            ="standard"
  engine                  ="postgres"        #The engine and instance class must be compatible. Learned the hard way :(
  #engine_version          ="12"             will leave this to be defined by terraform apply
  instance_class          ="db.t4g.micro"    #Error fixed!! WOOOO I WAS RIGHT!
  db_name                 ="postgres"        
  username                = var.db_user
  password                = var.db_pass
  skip_final_snapshot     ="true"
}


#
