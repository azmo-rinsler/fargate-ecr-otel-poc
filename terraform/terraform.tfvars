# AWS Account ID
aws_account = ""

# VPC to create this Fargate cluster in
vpc_id = ""

# Subnets related to the above VPC
subnets = ["", ""]

# CIDR block(s) to allow for ingress
vpc_cidr_ranges = ["0.0.0.0/0"] # all 0's opens up to everything