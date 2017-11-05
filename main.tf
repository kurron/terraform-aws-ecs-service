terraform {
    required_version = ">= 0.10.7"
    backend "s3" {}
}

provider "aws" {
    region     = "${var.region}"
}

resource "aws_ecs_service" "service" {
    name = "${var.name}"
    task_definition = "${var.task_definition_arn}"
    desired_count = "${var.desired_count}"
    cluster = "${var.cluster_arn}"
    iam_role = "${var.iam_role}"
    deployment_maximum_percent = "${var.deployment_maximum_percent}"
    deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
    load_balancer = {
        target_group_arn = "${var.target_group_arn}"
        container_name = "${var.container_name}"
        container_port = "${var.container_port}"
    }
    placement_strategy = {
        type = "binpack"
        field = "memory"
    }
}
