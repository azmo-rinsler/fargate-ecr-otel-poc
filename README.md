# Fargate ECR (Docker) Open Telemetry Collector

## Helpful Commands
- Create Terraform S3 Bucket: `aws s3 mb s3://fargate-ecr-otel-poc-tfstate --region us-east-1`
- Create ECR Repo: `aws ecr create-repository --repository-name otel-collector --region us-east-1`
- Update Fargate (after updating ECR image): `aws ecs update-service --cluster otel-collector-cluster --service otel-collector-service --force-new-deployment`
- Send test log (must have otel-cli): `otel-cli logs --endpoint=http://<IP_ADDRESS>:4318/v1/logs --body="Test Log Message"`

### From the docker folder
- Build image: `docker build -t otel-collector .`
- Tag image: `docker tag otel-collector:latest 145612473986.dkr.ecr.us-east-1.amazonaws.com/otel-collector:latest`
- Auth to ECR: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 145612473986.dkr.ecr.us-east-1.amazonaws.com`
- Push image: `docker push 145612473986.dkr.ecr.us-east-1.amazonaws.com/otel-collector:latest`

### From the terraform folder
- terraform init
- terraform plan
- terraform apply -auto-approve