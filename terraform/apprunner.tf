# # NOTE: According to ChatGPT, App Runner does not currently have good support for CloudFormation OR Terraform!
# #       This section is commented out because I'm not sure how to do things like enable observability via IaC.
# #       (but probably the best IaC approach would be to use the AWS CDK)
# # IAM Role for App Runner to access ECR
# resource aws_iam_role ecr_otel_poc_app_runner_access {
#   name = "apprunner-ecr-access-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "build.apprunner.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }
#
# resource aws_iam_role_policy ecr_otel_poc_app_runner_policy {
#   name = "AppRunnerEcrOtelPullPolicy"
#   role = aws_iam_role.ecr_otel_poc_app_runner_access.id
#
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchGetImage",
#           "ecr:GetDownloadUrlForLayer"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
#
# # App Runner service using a private ECR image
# resource aws_apprunner_service otel_collector {
#   service_name = "otel-collector"
#
#   source_configuration {
#     authentication_configuration {
#       access_role_arn = aws_iam_role.ecr_otel_poc_app_runner_access.arn
#     }
#
#     # App runner only supports HTTP, so we don't bother with port 4317 (gRPC)
#     image_repository {
#       image_identifier      = local.ecr_image
#       image_repository_type = "ECR"
#
#       image_configuration {
#         port = "4318"
#
#         runtime_environment_variables = {
#           OTEL_CONFIG_FILE = "/etc/otel-config.yaml"
#         }
#       }
#     }
#
#     auto_deployments_enabled = true
#   }
#
#   instance_configuration {
#     cpu    = "1024"
#     memory = "2048"
#   }
# }