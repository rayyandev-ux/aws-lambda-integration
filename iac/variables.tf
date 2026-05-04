variable "profile"{}
variable "region" {}
variable "suffix" {}

variable "config" {  //config para cada workspace xd
  type = map(object({
    lambda_memory_upload  = number
    lambda_memory_crop    = number
    lambda_timeout_upload = number
    lambda_timeout_crop   = number
    throttling_rate       = number
    throttling_burst      = number
    log_retention         = number
    dlq_retention         = number
  }))
}