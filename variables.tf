variable "region" {
    description = "Region being used"
    type        = "string"
    default     = "us-east-1"
}

variable "ami" {
    description = "Machine image for ec2 instance resource"
    type        = string
    default     = "ami-0c553fd621f67f9d7"
}

variable "instance_type" {
    description = "ami ec2 instance type"
    type        = string
    default     = "t.2 micro"
}  

variable "db_name" {
    description = "Name of database"
    type        = string
}

variable "db_user" {
    description = "Username for database"
    type        = string
}

variable "db_pass" {
    description = "Password for database"
    type        = string
    sensitive   = true
}