#####################################
# S3 Bucket Settings
#####################################
resource "aws_s3_bucket" "this" {
  bucket = "${local.domain}"
  acl    = "private"
}

data "aws_iam_policy_document" "s3_for_cloudfront" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.this.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_for_cloudfront" {
  bucket = "${aws_s3_bucket.this.id}"
  policy = "${data.aws_iam_policy_document.s3_for_cloudfront.json}"
}
