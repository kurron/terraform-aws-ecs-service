variable "region" {
    type = "string"
    description = "The AWS region to deploy into (e.g. us-east-1)"
}

variable "name" {
    type = "string"
    description = "What to name the service being created, e.g. MongoDB"
}

variable "task_definition_arn" {
    type = "string"
    description = "Full ARN of the task definition that you want to run in your service"
}

variable "desired_count" {
    type = "string"
    description = "The number of instances of the task definition to place and keep running, e.g. 2"
}

variable "cluster_arn" {
    type = "string"
    description = "ARN of an ECS cluster to deploy to."
}

variable "iam_role" {
    type = "string"
    description = "The ARN of IAM role that allows your Amazon ECS container agent to make calls to your load balancer on your behalf."
}

variable "deployment_maximum_percent" {
    type = "string"
    description = "The upper limit (as a percentage of the service's desired_count) of the number of running tasks that can be running in a service during a deployment, e.g. 200"
}

variable "deployment_minimum_healthy_percent" {
    type = "string"
    description = " The lower limit (as a percentage of the service's desired_count) of the number of running tasks that must remain running and healthy in a service during a deployment, e.g. 50"
}

variable "target_group_arn" {
    type = "string"
    description = "The ARN of the ALB target group to associate with the service."
}

variable "container_name" {
    type = "string"
    description = "The name of the container to associate with the load balancer (as it appears in a container definition)."
}

variable "container_port" {
    type = "string"
    description = "The port on the container to associate with the load balancer, e.g. 80"
}
