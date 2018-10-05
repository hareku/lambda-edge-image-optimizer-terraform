#####################################
# CloudFront Settings
#####################################
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "${local.domain}"
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = "${aws_s3_bucket.this.bucket_regional_domain_name}"
    origin_id   = "${local.domain}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path}"
    }
  }

  enabled     = true
  price_class = "PriceClass_All"
  aliases     = ["${local.domain}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${aws_acm_certificate.cloudfront.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.domain}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    max_ttl     = 0
    default_ttl = 0
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern           = "*.jpg"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.domain}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.origin_response.qualified_arn}"
    }

    min_ttl     = 0
    default_ttl = "${365 * 24 * 60 * 60}"
    max_ttl     = "${365 * 24 * 60 * 60}"
    compress    = true
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern           = "*.png"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.domain}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.origin_response.qualified_arn}"
    }

    min_ttl     = 0
    default_ttl = "${365 * 24 * 60 * 60}"
    max_ttl     = "${365 * 24 * 60 * 60}"
    compress    = true
  }
}
