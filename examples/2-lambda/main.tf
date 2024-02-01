# Setta variabili globali AWS
provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_role" "lambda_role" {
 name   = "terraform_aws_lambda_role"
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

# IAM policy per la lambda, per ora solo log

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Collegamento policy

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# Genera l'archivio che contiene il codice della lambda.

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/src/"
 output_path = "${path.module}/codice.zip"
}

# Crea la lambda
# In terraform ${path.module} è la posizione attuale.
# source_code_hash serve perchè se il codice cambia, quel valore cambia.
# senza quello, i cambiamenti del codice sorgente non vengono visti
resource "aws_lambda_function" "terraform_lambda_func" {
 filename                       = "${path.module}/codice.zip"
 source_code_hash               = "${data.archive_file.zip_the_python_code.output_base64sha256}"
 function_name                  = "test-function"
 role                           = aws_iam_role.lambda_role.arn
 handler                        = "index.lambda_handler"
 runtime                        = "python3.11"
 depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
 timeout                        = "300"
 memory_size                    = "1024"

 ephemeral_storage {
  size = 1024
 }
}


output "teraform_aws_role_output" {
 value = aws_iam_role.lambda_role.name
}

output "teraform_aws_role_arn_output" {
 value = aws_iam_role.lambda_role.arn
}

output "teraform_logging_arn_output" {
 value = aws_iam_policy.iam_policy_for_lambda.arn
}