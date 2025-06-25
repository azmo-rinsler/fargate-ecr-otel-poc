variable aws_region {
  type = string
  default = "us-east-1"
}

variable aws_account {
  type = string
}

variable ecr_repo_name {
  type = string
  default = "otel-collector"
}

variable subnets {
  type = list(string)
}

variable vpc_id {
  type = string
}

variable cidr_ranges {
  type = list(string)
}