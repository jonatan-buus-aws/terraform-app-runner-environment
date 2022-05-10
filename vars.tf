variable "service_name" {
    type = string
    default = "counterparty-fee-calculator"
    description = "The name of the App Runner Service that will be created."
}
variable "image" {
    type = string
    default = "dk.jonatanbuus/counterparty-fee-calculator:latest"
    description = "The name of the container image in ECR that the created App Runner Service will run."
}
variable "repository" {
    type = string
    default = "app-runner-repository"
    description = "The name of the container repository that will be created in ECR."
}
variable "environment_variables" {
    type = map(string)
    default = { "LOG_LEVEL" = "INFO" }
    description = "List of key / value pairs defining the environment variables for the provisioned App Runner Service"
}
variable "custom_domains" {
    type = list(string)
    default = [ ]
    description = "List of custom domains that will be mapped to the created App Runner Service."
}
variable "tags" {
    type = map(string)
    default = { "env" = "app-runner" }
    description = "List of key / value pairs defining the tags for the provisioned infrastructure"
}