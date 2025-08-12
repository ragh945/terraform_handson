variable "AWS_ACCESS_KEY" {
  type = string
  description = "AWS Access Key ID"
}

variable "AWS_SECRET_KEY" {
  type = string
  description = "AWS Secret Access Key"
  sensitive = true
}

variable "AWS_REGION" {
  type    = string
  default = "us-east-2"
  description = "AWS region to deploy resources"
}

variable "Security_Group" {
  type    = list(string)
  default = ["sg-01665d2385eef1636"]
  description = "List of security group IDs"
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0f40c8f97004632f9"
    us-east-2 = "ami-05692172625678b4e"
    us-west-2 = "ami-0352d5a37fb4f603f"
    us-west-1 = "ami-0f40c8f97004632f9"
  }
  description = "Map of AWS AMIs per region"
}

variable "PATH_TO_PRIVATE_KEY" {
  type        = string
  default     = "D:/terraform_keys/level_up_key.pem"
  description = "Path to private SSH key file"
}

variable "PATH_TO_PUBLIC_KEY" {
  type        = string
  default     = "keys/level_up_key.pub"
  description = "Path to public SSH key file"
}

variable "INSTANCE_USERNAME" {
  type        = string
  default     = "ubuntu"
  description = "SSH username for the instance"
}
