variable "AWS_ACCESS_KEY" {
    type = string
    default = "AKIASVQKH3Q4HFMRIOV7"
}

variable "AWS_SECRET_KEY" {}

variable "AWS_REGION" {
default = "us-east-2"
}

variable "AMIS" {
    type = map
    default = {
        us-east-1 = "ami-0f40c8f97004632f9"
        us-east-2 = "ami-05692172625678b4e"
        us-west-2 = "ami-0352d5a37fb4f603f"
        us-west-1 = "ami-0f40c8f97004632f9"
    }
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "D:/terraform_keys/level_up_key.pub"
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "D:/terraform_keys/level_up_key.pem"
}
variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}


