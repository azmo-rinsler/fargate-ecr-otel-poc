environment = "ea-nonprod"

# EA Nonprod account
aws_account = "145612473986"

# IT Enterprise Architecture VPC nonprod
vpc_id = "vpc-0d91a43a500c1012c"

# IDEXX Transit Gateway VPC subnet(s) (1a, 1b, 1c, 1d) nonprod
subnets = [
  "subnet-06111d4ead241064e",
  "subnet-0dc560748c7831a36",
  "subnet-05e394cefa3a14898",
  "subnet-0ccc9e498fb20b7be"
]

# EFX-RDS-us-east-1-nonprod
# vpc_id = "vpc-0075bf297a5e37391"

# Private subnets within the above vpc (there are also 2 public subnets not used here)
# subnets = [
#   "subnet-0ccef74db6979b70a", # EFX-RDS-us-east-1-nonprod-Az1PrivateSubnet
#   "subnet-081a9576cc30af252"  # EFX-RDS-us-east-1-nonprod-Az2PrivateSubnet
# ]