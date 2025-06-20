variable aws_region {
  type = string
  default = "us-east-1"
}

variable ecr_image {
  type = string
}

variable subnets {
  type = list(string)
}

variable vpc_id {
    type = string
}