variable "region" {
  type = string
  default = "us-east-2"
}

provider "aws" {
  region = var.region
  access_key = ""
  secret_key = ""
}

resource "aws_lambda_function" "lambda1" {
   function_name = "lambda1"

   s3_bucket = "first-lambda-dev-serverlessdeploymentbucket-q0i6601szjvy"

   s3_key    = "tf-lambda/lambda.zip"
   handler = "index.handler"
   runtime = "nodejs12.x"
   role = aws_iam_role.lambda_role.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# API GAteway
######################################################################
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "LamdbaExample"
  description = "Terraform AWS Lambda Application Example"
}
######################################################################


####################################################################
resource "aws_api_gateway_resource" "resource1" {
   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
   path_part   = "test"
}

resource "aws_api_gateway_method" "method1" {
   rest_api_id   = aws_api_gateway_rest_api.rest_api.id
   resource_id   = aws_api_gateway_resource.resource1.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda1" {
   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   resource_id = aws_api_gateway_method.method1.resource_id
   http_method = aws_api_gateway_method.method1.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda1.invoke_arn
}

resource "aws_api_gateway_method" "method1_root" {
   rest_api_id   = aws_api_gateway_rest_api.rest_api.id
   resource_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda1_root" {
   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   resource_id = aws_api_gateway_method.method1_root.resource_id
   http_method = aws_api_gateway_method.method1_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda1.invoke_arn
}

resource "aws_api_gateway_deployment" "example1" {
   depends_on = [
     aws_api_gateway_integration.lambda1,
     aws_api_gateway_integration.lambda1_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   stage_name  = "test"
}

resource "aws_lambda_permission" "lambda1_permission" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.lambda1.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}
######################################################################

######################################################################
resource "aws_lambda_function" "lambda2" {
   function_name = "lambda2"

   # The bucket name as created earlier with "aws s3api create-bucket"
   s3_bucket = "first-lambda-dev-serverlessdeploymentbucket-q0i6601szjvy"
   s3_key    = "tf-lambda/lambda2.zip"
   handler = "index2.handler"
   runtime = "nodejs12.x"
   role = aws_iam_role.lambda_role.arn
}

resource "aws_api_gateway_resource" "resource2" {
   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
   path_part   = "test2"
}

resource "aws_api_gateway_method" "method2" {
   rest_api_id   = aws_api_gateway_rest_api.rest_api.id
   resource_id   = aws_api_gateway_resource.resource2.id
   http_method   = "GET"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda2" {
   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   resource_id = aws_api_gateway_method.method2.resource_id
   http_method = aws_api_gateway_method.method2.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda2.invoke_arn
}

resource "aws_api_gateway_deployment" "example2" {
   depends_on = [
     aws_api_gateway_integration.lambda2
   ]

   rest_api_id = aws_api_gateway_rest_api.rest_api.id
   stage_name  = "test"
}

resource "aws_lambda_permission" "lambda2_permission" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.lambda2.function_name
   principal     = "apigateway.amazonaws.com"

   source_arn = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}
######################################################################
