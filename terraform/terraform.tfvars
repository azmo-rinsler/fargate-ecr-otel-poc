# NOTE: This file is meant more as an example or template - check the env folder for "actual" values.

# AWS Account ID
aws_account = ""

# VPC to create this Fargate cluster in
vpc_id = ""

# Subnets related to the above VPC
subnets = ["", ""]

# CIDR block(s) to allow for ingress
cidr_ranges = ["0.0.0.0/0"] # all 0's opens up to everything