variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "us-east-2"
}

variable "AMIS" {
    type = map
    default = {
        us-east-2 = "ami-0568773882d492fc8"
        us-east-1 = "ami-05fa00d4c63e32376"
    }
  
}

variable "PATH_PRIVATE_KEY" {
  default = "privatekey"
}

variable "PATH_PUBLIC_KEY" {
    default = "public.key"
}

variable "INSTANCE_USERNAME" {
    default = "ec2-user"
}

variable "MYSQL_Password" {
    type = string
}

variable "VPC_IP_POOL" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_pool" {
    type = string
    default = "10.0.0.0/24"
  
}