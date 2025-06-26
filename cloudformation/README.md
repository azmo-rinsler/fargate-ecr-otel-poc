# GitHub OIDC Role Cloudformation Template

This CloudFormation template creates an IAM role that allows GitHub Actions to assume the role using OpenID Connect 
(OIDC) authentication. This is useful for securely granting permissions to GitHub Actions workflows without needing to
manage long-lived credentials.

It must be run to create the role BEFORE you can use it in your GitHub Actions workflows.

You can use the AWS CLI v2 to deploy this template via the following command:

Note: Make sure your working directory is set to the location of the `github-role.yaml` file before running the command.

```bash
aws cloudformation deploy --stack-name GitHubOidcRoleOtel --template-file github-role.yaml --capabilities CAPABILITY_NAMED_IAM
```

It may be necessary to update your AWS credentials in environment variables before the above command will work. 

You can set these in a variety of ways; the easiest method probably being to use MyApps to select the target account, 
clicking on Access Keys, and following the instructions under the tab of your choosing. PowerShell has a command you 
can copy and paste into your terminal to set these.

Once the role exists, it will be automatically used by GitHub Actions based on the aws_region and aws_account_id inputs.