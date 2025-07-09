variable environment {
  type = string
}

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

variable ecr_repo_version {
  type = string
  default = "latest"
}

variable subnets {
  type = list(string)
}

variable vpc_id {
  type = string
}

variable cidr_ranges {
  type = list(string)
  # IDEXX CIDR Ranges
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}