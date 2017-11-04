terraform {
    required_version = ">= 0.10.7"
    backend "s3" {}
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/networking/vpc/terraform.tfstate"
        region = "us-east-1"
    }
}

data "terraform_remote_state" "security-groups" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/networking/security-groups/terraform.tfstate"
        region = "us-east-1"
    }
}

data "terraform_remote_state" "bastion" {
    backend = "s3"
    config {
        bucket = "transparent-test-terraform-state"
        key    = "us-west-2/debug/compute/bastion/terraform.tfstate"
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

module "ecs" {
    source = "../"

    region                           = "us-west-2"
    name                             = "Debug_Cluster"
    project                          = "Debug"
    purpose                          = "Docker scheduler"
    creator                          = "kurron@jvmguy.com"
    environment                      = "development"
    freetext                         = "Workers are based on spot intances."
    ami_regexp                       = "^amzn-ami-.*-amazon-ecs-optimized$"
    instance_type                    = "m3.medium"
    instance_profile                 = "${data.terraform_remote_state.iam.ecs_profile_id}"
    ssh_key_name                     = "${data.terraform_remote_state.bastion.ssh_key_name}"
    security_group_ids               = ["${data.terraform_remote_state.security-groups.ec2_id}"]
    ebs_optimized                    = "false"
    spot_price                       = "0.0670"
    cluster_min_size                 = "1"
    cluster_desired_size             = "${length( data.terraform_remote_state.vpc.public_subnet_ids )}"
    cluster_max_size                 = "${length( data.terraform_remote_state.vpc.public_subnet_ids )}"
    cooldown                         = "90"
    health_check_grace_period        = "300"
    subnet_ids                       = "${data.terraform_remote_state.vpc.public_subnet_ids}"
    scale_down_cron                  = "0 7 * * SUN-SAT"
    scale_up_cron                    = "0 0 * * MON-FRI"
    cluster_scaled_down_min_size     = "0"
    cluster_scaled_down_desired_size = "0"
    cluster_scaled_down_max_size     = "0"
}
