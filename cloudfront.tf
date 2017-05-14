resource "aws_cloudfront_distribution" "imghosting" {
  comment = "imghosting ${var.name}"
  origin {
    domain_name = "imghosting-${var.name}.s3-website-${var.region}.amazonaws.com"
    origin_id   = "imghostingS3"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["SSLv3"]
    }
  }


  restrictions {
  	geo_restriction {
  		restriction_type = "none"
  	}
  }

  viewer_certificate {
  	cloudfront_default_certificate = true
  }

  enabled             = true

  aliases = ["${var.aliases}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "imghostingS3"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
  }
}

output cloudfront_domain_name {
  value = "${aws_cloudfront_distribution.imghosting.domain_name}"
}

output cloudfront_hosted_zone_id {
  value = "${aws_cloudfront_distribution.imghosting.hosted_zone_id}"
}