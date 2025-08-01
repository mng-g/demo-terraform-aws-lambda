output "current_environment" {
  value = terraform.workspace
}

output "lambda_function_name" {
  value = aws_lambda_function.example_lambda.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.example_lambda.arn
}

output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
