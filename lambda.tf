resource "aws_iam_role" "iam_for_imgscaler_lambda" {
    name = "iam_for_lambda_${var.name}"
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

resource "aws_iam_role_policy" "iam_for_imgscaler_lambda" {
    name = "imgscaler_${var.name}"
    role = "${aws_iam_role.iam_for_imgscaler_lambda.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${aws_s3_bucket.imghosting.arn}",
        "${aws_s3_bucket.imghosting.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_lambda_function" "imghosting-scaler" {
    filename = "${path.module}/scaler.zip"
    function_name = "imghosting-scaler-${var.name}"
    role = "${aws_iam_role.iam_for_imgscaler_lambda.arn}"
    runtime = "nodejs6.10"
    timeout = 20
    memory_size = 512
    handler = "scaler.scale"
    source_code_hash = "${base64sha256(file("${path.module}/scaler.zip"))}"
    environment {
      variables {
        BUCKET = "imghosting-${var.name}"
        BUCKET_URL = "http://imghosting-${var.name}.s3-website-${var.region}.amazonaws.com/"
        SECRET = "${var.secret}"
      }
    }
}

resource "aws_lambda_permission" "allow_api_gateway" {
    function_name = "${aws_lambda_function.imghosting-scaler.function_name}"
    statement_id = "AllowExecutionFromApiGateway-${var.name}"
    action = "lambda:InvokeFunction"
    principal = "apigateway.amazonaws.com"
}

resource "aws_lambda_function" "imghosting-cleanup" {
    filename = "${path.module}/cleanup.zip"
    function_name = "imghosting-cleanup-${var.name}"
    role = "${aws_iam_role.iam_for_imgscaler_lambda.arn}"
    runtime = "nodejs6.10"
    handler = "cleanup.cleanup"
    source_code_hash = "${base64sha256(file("${path.module}/cleanup.zip"))}"
    environment {
      variables {
        BUCKET = "imghosting-${var.name}"
        BUCKET_URL = "http://imghosting-${var.name}.s3-website-${var.region}.amazonaws.com/"
        SECRET = "hufflepuff"
      }
    }
}

