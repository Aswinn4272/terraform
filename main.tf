provider "aws" {
  region = "ap-south-1"
  access_key = your_access_key
  secret_key = your_secret_key
}

#create s3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "bucket_name"

  tags = {
    Name        = "samble bucket"
    Environment = "Dev"
  }
}

# creating an iam role
resource "aws_iam_role" "test_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = "${aws_iam_role.lambda_role.id}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = "${file("iam/lambda-policy.json")}"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = "${file("iam/lambda-assume-policy.json")}" 
}

locals{
  lambda_zip_location = "outputs/tflambda.zip"
}

data "archive_file" "tflambda" {
  type        = "zip"
  source_file = "tflambda.py"
  output_path = "${local.lambda_zip_location}"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "${local.lambda_zip_location}"
  function_name = "tflambda"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "tflambda.lambda_handler"
  runtime       = "python3.9"

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }
}

#link for adding trigger to the lambda function
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping

resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.example.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}
resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.example.id}"
}
