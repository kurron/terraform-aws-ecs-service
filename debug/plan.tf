terraform {
    required_version = ">= 0.10.7"
    backend "s3" {}
}

provider "aws" {
    region     = "${var.region}"
}

variable "domain_name" {
    type = "string"
    default = "transparent.engineering"
}

data "aws_acm_certificate" "certificate" {
    domain   = "*.${var.domain_name}"
    statuses = ["ISSUED"]
}

data "terraform_remote_state" "ecs_cluster" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/compute/ecs/terraform.tfstate"
        region = "us-east-1"
    }
}

data "terraform_remote_state" "iam" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/security/iam/terraform.tfstate"
        region = "us-east-1"
    }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/networking/vpc/terraform.tfstate"
        region = "us-east-1"
    }
}

data "terraform_remote_state" "alb" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/compute/alb/terraform.tfstate"
        region = "us-east-1"
    }
}

variable "region" {
    type = "string"
    default = "us-west-2"
}

resource "aws_ecs_task_definition" "definition" {
    family                = "Nginx"
    container_definitions = "${file("debug/files/task-definition.json")}"
    network_mode          = "bridge"
}

module "ecs_service" {
    source = "../"

    region                         = "${var.region}"
    name                           = "Nginx"
    project                        = "Debug"
    purpose                        = "Balance to Nginx containers"
    creator                        = "kurron@jvmguy.com"
    environment                    = "development"
    freetext                       = "Using insecure communications"

    enable_stickiness              = "Yes"
    health_check_interval          = "15"
    health_check_path              = "/"
    health_check_timeout           = "5"
    health_check_healthy_threshold = "5"
    unhealthy_threshold            = "2"
    matcher                        = "200-299"

    path_pattern                   = "/alpha/*"
    rule_priority                  = "1"
    vpc_id                         = "${data.terraform_remote_state.vpc.vpc_id}"
    secure_listener_arn            = "${data.terraform_remote_state.alb.secure_listener_arn}"
    insecure_listener_arn          = "${data.terraform_remote_state.alb.insecure_listener_arn}"


    task_definition_arn                = "${aws_ecs_task_definition.definition.arn}"
    desired_count                      = "2"
    cluster_arn                        = "${data.terraform_remote_state.ecs_cluster.cluster_arn}"
    iam_role                           = "${data.terraform_remote_state.iam.ecs_role_arn}"
    deployment_maximum_percent         = "200"
    deployment_minimum_healthy_percent = "50"
    container_name                     = "Nginx"
    container_port                     = "80"
    container_protocol                 = "HTTP"
}
