data "terraform_remote_state" "dvpc" {
  backend = "s3"
  config = {
    bucket = "my-vpc-bucket-tf-dev"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_autoscaling_group" "demo-asg" {
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 3
  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true

  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  launch_template {
    id      = aws_launch_template.demo-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                    = "scale-up-policy"
  scaling_adjustment      = 1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 300
  metric_aggregation_type = "Average"

  autoscaling_group_name = aws_autoscaling_group.demo-asg.name
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                    = "scale-down-policy"
  scaling_adjustment      = -1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 300
  metric_aggregation_type = "Average"

  autoscaling_group_name = aws_autoscaling_group.demo-asg.name
}

# High CPU Alarm - Triggers Scale Up
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Trigger when CPU exceeds 70%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.demo-asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

# Low CPU Alarm - Triggers Scale Down
resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Trigger when CPU drops below 30%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.demo-asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
}
