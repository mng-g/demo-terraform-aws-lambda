// This Terraform configuration sets up an AWS Lambda function with an API Gateway trigger.

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  # lifecycle {
  #   create_before_destroy = true
  #   prevent_destroy       = true
  #   ignore_changes        = [name]
  # }
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "attach_lambda_basic_${terraform.workspace}"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "lambda_code" {
  bucket        = "${var.project_name}-${terraform.workspace}-lambda-code"
  force_destroy = true
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_code.bucket
  key    = "lambda.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# Lambda function configuration
resource "aws_lambda_function" "example_lambda" {
  function_name = "example_lambda_${terraform.workspace}"
  runtime       = "python3.11"
  handler       = "handler.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn

  s3_bucket = aws_s3_bucket.lambda_code.bucket
  s3_key    = aws_s3_object.lambda_zip.key

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      ENV       = terraform.workspace
      S3_BUCKET = "${var.project_name}-${terraform.workspace}-lambda-code"
      DB_DSN    = "postgresql://postgres:postgres@localhost:5432/postgres"
    }
  }
}

// API Gateway configuration
resource "aws_apigatewayv2_api" "http_api" {
  name          = "lambda_http_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.example_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id = aws_apigatewayv2_api.http_api.id
  #route_key = "GET /"
  route_key = "ANY /{proxy+}" # catch-all route
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
