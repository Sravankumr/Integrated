resource "aws_cloudwatch_event_rule" "event_rule" {
  schedule_expression = var.lambda_schedule_expression
  name = var.cloudwatch_event_name
}

resource "aws_cloudwatch_event_target" "check_at_rate" {
  rule = aws_cloudwatch_event_rule.event_rule.name
  arn = aws_lambda_function.lambda_function.arn
}

resource "aws_sqs_queue" "gselector_sqs_queue" {
    name = "gselector_sqs_queue"
    message_retention_seconds = 86400
    visibility_timeout_seconds = 900

    tags = {
    Environment = "non-production"
  }
}

resource "aws_lambda_function" "lambda_function" {
  role             = "${aws_iam_role.lambda_exec_role.arn}"
  handler          = "${var.handler}"
  runtime          = "${var.runtime}"
  filename         = "lambda.zip"
  function_name    = "${var.lambda_function_name}"
  source_code_hash = "${filebase64sha256("lambda.zip")}"

  environment {
    variables = {
      queue_url = "${aws_sqs_queue.gselector_sqs_queue.id}"
      dynamotablename = "${var.dynamotablename}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.event_rule.arn
  depends_on = [aws_lambda_function.lambda_function]
}

resource "aws_iam_role" "lambda_exec_role" {
  name        = "lambda_exec"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_dynamodb_table" "ddbtable" {
  name             = "${var.dynamotablename}"
  hash_key         = "StationID"
  # billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  attribute {
    name = "StationID"
    type = "S"
  }
}

resource "aws_iam_role" "gselector_lambda_exec_role" {
  name        = "gselector_lambda_exec"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "gselector_lambda_policy"
  role = "${aws_iam_role.gselector_lambda_exec_role.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
      ],
      "Resource": "${aws_sqs_queue.gselector_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}


resource "aws_lambda_function" "gselectorapi_lambda_function" {
  role             = "${aws_iam_role.gselector_lambda_exec_role.arn}"
  handler          = "${var.gselector_handler}"
  runtime          = "${var.runtime}"
  filename         = "gselectorapi_lambda.zip"
  function_name    = "${var.gselector_lambda_function_name}"
  source_code_hash = "${filebase64sha256("gselectorapi_lambda.zip")}"
  timeout          = 600

  vpc_config {
    subnet_ids         = ["subnet-41364b6d", "subnet-43ebdc0b"]
    security_group_ids = ["sg-000262c9a3c10bffa","sg-00393706a1ea6ff48"]
  }
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = "${aws_sqs_queue.gselector_sqs_queue.arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.gselectorapi_lambda_function.arn}"
  depends_on = ["aws_iam_role_policy.lambda_policy"]
  batch_size       = 1
}