resource "aws_s3_bucket" "imghosting" {
    bucket = "imghosting-${var.name}"
    force_destroy = true
    
    tags {
        Name = "Image Hosting for ${var.name}"
    }

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::imghosting-${var.name}/*"
        }
    ]
}
EOF

    website {
        index_document = "index.html"
        routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "s/",
        "HttpErrorCodeReturnedEquals": "404"
    },
    "Redirect": {
        "Protocol": "https",
    	"HostName": "${aws_api_gateway_rest_api.imghosting.id}.execute-api.${var.region}.amazonaws.com",
        "HttpRedirectCode": "302",
        "ReplaceKeyPrefixWith": "prod/s/"
    }
}]
EOF
    }
}

resource "aws_iam_access_key" "uploader" {
    user = "${aws_iam_user.uploader.name}"
}

output "id" {
  value = "${aws_iam_access_key.uploader.id}"
}

output "secret" {
  value = "${aws_iam_access_key.uploader.secret}"
}

resource "aws_iam_user" "uploader" {
    name = "uploader-${var.name}"
    path = "/imghosting/"
}

resource "aws_iam_user_policy" "uploader" {
    name = "imagehosting-uploader"
    user = "${aws_iam_user.uploader.name}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1478193134000",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::imghosting-${var.name}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_lambda_permission" "allow_bucket" {
    statement_id = "AllowExecutionFromS3Bucket"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.imghosting-cleanup.arn}"
    principal = "s3.amazonaws.com"
    source_arn = "${aws_s3_bucket.imghosting.arn}"
}


resource "aws_s3_bucket_notification" "imghosting" {
    bucket = "${aws_s3_bucket.imghosting.id}"
    lambda_function {
        lambda_function_arn = "${aws_lambda_function.imghosting-cleanup.arn}"
        events = ["s3:ObjectRemoved:Delete"]
        filter_prefix = "o/"
    }
}

output s3_arn {
  value = "${aws_s3_bucket.imghosting.arn}"
}
