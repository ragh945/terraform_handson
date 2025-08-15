# Variable for Create Instance Module
variable "public_key_path" {
  description = "Public key path"
  default = "D:/terraform_keys/level_up_key.pub"

}

variable "ENVIRONMENT" {
    type    = string
    default = "development"
}

variable "AMI_ID" {
    type    = string
    default = ""
}

variable "AWS_REGION" {
default = "us-east-2"
}

variable "INSTANCE_TYPE" {
  default = "t2.micro"
}