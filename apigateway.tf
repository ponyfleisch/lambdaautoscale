resource "aws_api_gateway_rest_api" "imghosting" {
  name = "imghosting-${var.name}"
  description = "Img scaler endpoint for ${var.name}"
}

resource "aws_api_gateway_resource" "imghosting" {
  rest_api_id = "${aws_api_gateway_rest_api.imghosting.id}"
  parent_id = "${aws_api_gateway_rest_api.imghosting.root_resource_id}"
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "imghosting" {
  rest_api_id = "${aws_api_gateway_rest_api.imghosting.id}"
  resource_id = "${aws_api_gateway_resource.imghosting.id}"
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.imghosting.id}"
  resource_id = "${aws_api_gateway_resource.imghosting.id}"
  http_method = "${aws_api_gateway_method.imghosting.http_method}"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.imghosting-scaler.arn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "imghosting" {
  depends_on = ["aws_api_gateway_integration.lambda"]
  rest_api_id = "${aws_api_gateway_rest_api.imghosting.id}"
  stage_name = "prod"
}
