terraform {
    required_version = ">= 0.10.7"
    backend "s3" {}
}

provider "aws" {
    region     = "${var.region}"
}

data "aws_ami" "lookup" {
    most_recent = true
    name_regex  = "${var.ami_regexp}"
    owners      = ["amazon"]
    filter {
       name   = "architecture"
       values = ["x86_64"]
    }
    filter {
       name   = "image-type"
       values = ["machine"]
    }
    filter {
       name   = "state"
       values = ["available"]
    }
    filter {
       name   = "virtualization-type"
       values = ["hvm"]
    }
    filter {
       name   = "hypervisor"
       values = ["xen"]
    }
    filter {
       name   = "root-device-type"
       values = ["ebs"]
    }
}

resource "aws_ecs_cluster" "main" {
    name = "${var.name}"

    lifecycle {
        create_before_destroy = true
    }
}

data "template_file" "ecs_cloud_config" {
    template = "${file("${path.module}/files/cloud-config.yml.template")}"
    vars {
        cluster_name = "${aws_ecs_cluster.main.name}"
    }
}

data "template_cloudinit_config" "cloud_config" {
    gzip          = false
    base64_encode = false
    part {
        content_type = "text/cloud-config"
        content      = "${data.template_file.ecs_cloud_config.rendered}"
    }
}

resource "aws_launch_configuration" "worker_spot" {
    name_prefix          = "${var.name}-"
    image_id             = "${data.aws_ami.lookup.id}"
    instance_type        = "${var.instance_type}"
    iam_instance_profile = "${var.instance_profile}"
    key_name             = "${var.ssh_key_name}"
    security_groups      = ["${var.security_group_ids}"]
    user_data            = "${data.template_cloudinit_config.cloud_config.rendered}"
    enable_monitoring    = true
    ebs_optimized        = "${var.ebs_optimized}"
    spot_price           = "${var.spot_price}"
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "worker_spot" {
    name_prefix               = "${var.name}"
    max_size                  = "${var.cluster_max_size}"
    min_size                  = "${var.cluster_min_size}"
    default_cooldown          = "${var.cooldown}"
    launch_configuration      = "${aws_launch_configuration.worker_spot.name}"
    health_check_grace_period = "${var.health_check_grace_period}"
    health_check_type         = "EC2"
    desired_capacity          = "${var.cluster_desired_size}"
    vpc_zone_identifier       = ["${var.subnet_ids}"]
    termination_policies      = ["ClosestToNextInstanceHour", "OldestInstance", "Default"]
    enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
    lifecycle {
        create_before_destroy = true
    }
    tag {
        key                 = "Name"
        value               = "ECS Worker (spot)"
        propagate_at_launch = true
    }
    tag {
        key                 = "Project"
        value               = "${var.project}"
        propagate_at_launch = true
    }
    tag {
        key                 = "Purpose"
        value               = "ECS Worker (spot)"
        propagate_at_launch = true
    }
    tag {
        key                 = "Creator"
        value               = "${var.creator}"
        propagate_at_launch = true
    }
    tag {
        key                 = "Environment"
        value               = "${var.environment}"
        propagate_at_launch = true
    }
    tag {
        key                 = "Freetext"
        value               = "${var.freetext}"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_schedule" "spot_scale_up" {
    autoscaling_group_name = "${aws_autoscaling_group.worker_spot.name}"
    scheduled_action_name  = "ECS Worker Scale Up (spot)"
    recurrence             = "${var.scale_up_cron}"
    min_size               = "${var.cluster_min_size}"
    max_size               = "${var.cluster_max_size}"
    desired_capacity       = "${var.cluster_desired_size}"
}

resource "aws_autoscaling_schedule" "spot_scale_down" {
    autoscaling_group_name = "${aws_autoscaling_group.worker_spot.name}"
    scheduled_action_name  = "ECS Worker Scale Down (spot)"
    recurrence             = "${var.scale_down_cron}"
    min_size               = "${var.cluster_scaled_down_min_size}"
    max_size               = "${var.cluster_scaled_down_max_size}"
    desired_capacity       = "${var.cluster_scaled_down_desired_size}"
}
