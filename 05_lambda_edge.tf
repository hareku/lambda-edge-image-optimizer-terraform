#####################################
# Lambda IAM Settings
#####################################
data "aws_iam_policy_document" "lambda_edge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_edge" {
  name               = "AWSLambdaEdgeRole"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_edge_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_edge_basic_execution" {
  role       = "${aws_iam_role.lambda_edge.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_s3_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_policy" "lambda_s3_bucket" {
  name   = "S3BucketPolicy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.lambda_s3_bucket.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_bucket" {
  role       = "${aws_iam_role.lambda_edge.name}"
  policy_arn = "${aws_iam_policy.lambda_s3_bucket.arn}"
}

#####################################
# Lambda Settings
#####################################
data "archive_file" "lambda_origin_response" {
  type        = "zip"
  source_dir  = "lambda_origin_response"
  output_path = "lambda_origin_response.zip"
}

resource "aws_lambda_function" "origin_response" {
  provider         = "aws.us-east-1"
  function_name    = "ImageOptimizerOriginResponse"
  filename         = "${data.archive_file.lambda_origin_response.output_path}"
  source_code_hash = "${data.archive_file.lambda_origin_response.output_base64sha256}"
  role             = "${aws_iam_role.lambda_edge.arn}"
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  timeout          = 5
  publish          = true
  memory_size      = 3008
}
