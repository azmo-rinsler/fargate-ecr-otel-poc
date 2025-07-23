#!/bin/bash

# Vars
AWS_REGION="${AWS_REGION:-"us-east-1"}"
AWS_ACCOUNT="${AWS_ACCOUNT:-"145612473986"}" # EA Nonprod
ECR_REPO_NAME="${ECR_REPO_NAME:-"otel-collector"}"
ECR_IMG_TAG="${ECR_IMG_TAG:-"2.21"}"

# Derived Vars
ECR_URI="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"


echo "Building Docker image"
docker build -t ${ECR_REPO_NAME} .

echo "Tagging image"
if [ ${ECR_IMG_TAG} != "latest" ]; then
  echo "Tagging image with ECR image tag: ${ECR_IMG_TAG}"
  docker tag ${ECR_REPO_NAME}:latest ${ECR_URI}:${ECR_IMG_TAG}
fi
docker tag ${ECR_REPO_NAME}:latest ${ECR_URI}:latest

echo "Authenticating to ECR"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Pushing image to ECR"
if [ ${ECR_IMG_TAG} != "latest" ]; then
  echo "Pushing image with ECR image tag: ${ECR_IMG_TAG}"
  docker push ${ECR_URI}:${ECR_IMG_TAG}
fi
docker push ${ECR_URI}:latest

echo "All done!"