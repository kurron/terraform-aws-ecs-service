terraform {
    required_version = ">= 0.10.7"
    backend "s3" {}
}

provider "aws" {
    region     = "${var.region}"
}

resource "aws_lb_target_group" "target_group" {
    name_prefix          = "ecs-"
    port                 = "${var.container_port}"
    protocol             = "${var.container_protocol}"
    vpc_id               = "${var.vpc_id}"
    deregistration_delay = 300
    stickiness {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = "${var.enable_stickiness == "Yes" ? true : false}"
    }
    health_check {
        interval            = "${var.health_check_interval}"
        path                = "${var.health_check_path}"
        port                = "traffic-port"
        protocol            = "${var.container_protocol}"
        timeout             = "${var.health_check_timeout}"
        healthy_threshold   = "${var.health_check_healthy_threshold}"
        unhealthy_threshold = "${var.unhealthy_threshold}"
        matcher             = "${var.matcher}"
    }
    tags {
        Name        = "${var.name}"
        Project     = "${var.project}"
        Purpose     = "${var.purpose}"
        Creator     = "${var.creator}"
        Environment = "${var.environment}"
        Freetext    = "${var.freetext}"
    }
}

resource "aws_lb_listener_rule" "insecure_rule" {
    listener_arn = "${var.insecure_listener_arn}"
    priority     = "${var.rule_priority}"
    action = {
        target_group_arn = "${aws_lb_target_group.target_group.arn}"
        type             = "forward"
    }
    condition = {
        field = "path-pattern"
        values = ["${var.path_pattern}"]
    }
}

resource "aws_lb_listener_rule" "secure_rule" {
    listener_arn = "${var.secure_listener_arn}"
    priority     = "${var.rule_priority}"
    action = {
        target_group_arn = "${aws_lb_target_group.target_group.arn}"
        type             = "forward"
    }
    condition = {
        field = "path-pattern"
        values = ["${var.path_pattern}"]
    }
}

resource "aws_ecs_service" "service" {
    name                               = "${var.name}"
    task_definition                    = "${var.task_definition_arn}"
    desired_count                      = "${var.desired_count}"
    cluster                            = "${var.cluster_arn}"
    iam_role                           = "${var.iam_role}"
    deployment_maximum_percent         = "${var.deployment_maximum_percent}"
    deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
    load_balancer = {
        target_group_arn = "${aws_lb_target_group.target_group.arn}"
        container_name   = "${var.container_name}"
        container_port   = "${var.container_port}"
    }
    placement_strategy = {
        type  = "spread"
        field = "instanceId"
    }
}
