# Fargate ECR (Docker) Open Telemetry Collector

To run most of the commands below, you will need to have the AWS CLI installed and be authenticated.
- Use `aws configure` and/or `aws sso login --profile <profile_name>` to authenticate
- Set your environment property `AWS_PROFILE` to the same profile you used for SSO
  - Powershell: `$Env:AWS_PROFILE="<profile_name>"`
  - Bash: `export AWS_PROFILE="<profile_name>"`

To run the Docker commands, you will need to have Docker installed and running.

You will typically want to build, tag and push the Docker image to ECR before deploying it to Fargate (do the Terraform stuff second).

## Helpful Commands
- Create Terraform S3 Bucket: `aws s3 mb s3://fargate-ecr-otel-poc-tfstate --region us-east-1`
- Create ECR Repo: `aws ecr create-repository --repository-name otel-collector --region us-east-1`
- Update Fargate (after updating ECR image): `aws ecs update-service --cluster otel-collector-cluster --service otel-collector-service --force-new-deployment`
- Send test log (must have otel-cli): `otel-cli logs --endpoint=http://<IP_ADDRESS>:4318/v1/logs --body="Test Log Message"`

> [!Warning]
> Updating the Docker image will not automatically update Fargate. 
> You have to specifically tell it to update after pushing any changes to the image.
> If you do this (Update Fargate), it will most likely end up with a new IP address, which you will need to update in 
> any corresponding config files (e.g., in pacs-indexx)


### From the docker folder
- Build image: `docker build -t otel-collector .`
- Tag image: `docker tag otel-collector:latest 145612473986.dkr.ecr.us-east-1.amazonaws.com/otel-collector:latest`
- Auth to ECR: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 145612473986.dkr.ecr.us-east-1.amazonaws.com`
- Push image: `docker push 145612473986.dkr.ecr.us-east-1.amazonaws.com/otel-collector:latest`

### From the terraform folder
- terraform init
- terraform plan
- terraform apply -auto-approve -var-file="env/nonprod.tfvars"