variable "component" {}
variable "deployment_identifier" {}

variable "lambda_function_name" {
  default = "lambda_dynamo_reader"
}

variable "cloudwatch_event_name" {
  default = "dynamo_reader_cloudwatch_event"
}


variable "lambda_schedule_expression" {
  description = "Lambda schedule expression. Defaults to every 5 minutes"
  default     = "rate(5 minutes)"
}

variable "handler" {
  default = "lambda.handler"
}

variable "runtime" {
  default = "python3.6"
}

variable "dynamotablename"{
  default = "gselector"
}

variable "gselector_handler" {
    default = "lambda_function.lambda_handler"
}

variable "gselector_lambda_function_name" {
  default = "Gselector_API_Call"
}

variable myprofile {}
variable aws_region{}