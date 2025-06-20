variable aws_region {
  type = string
  default = "us-east-1"
}

variable aws_account {
  type = string
}

variable subnets {
  type = list(string)
}

variable vpc_id {
  type = string
}

variable vpc_cidr_ranges {
  type = list(string)
}