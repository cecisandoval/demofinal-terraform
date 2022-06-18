

#Create key-pair for  EC2 
#resource "aws_key_pair" "instance_key" {
  #provider = aws.region-master
  #key_name = "mykey"
  #public_key = file("~/.ssh/id_rsa.pub")
#}



#create EC2 instance 
resource "aws_instance" "web_server1" {
    provider = aws.region-master-
    ami = var.ami-master
    instance_type = var.instance-type
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.sgw.id]
    subnet_id = aws_subnet.sub_private1.id
    key_name = "mykey"
    #user_data = "${file("install_apache.sh")}"

    tags = {
	Name = "web_server1"	
	#Batch = "5AM"
    }
}


#create EC2 instance MsQL
resource "aws_instance" "msql_server1" {
    provider = aws.region-master
    ami = var.ami-msql
    instance_type = var.instance-type
    associate_public_ip_address = false
    vpc_security_group_ids = [aws_security_group.sgmsql.id]
    subnet_id = aws_subnet.sub_privatemsql1.id
    key_name = "mykey"
    #user_data = "${file("install_apache.sh")}"
    tags = {
	Name = "msql_server1"	
	#Batch = "5AM"
    }
}


#create Application LoadBalancer
resource "aws_lb" "application_lb" {
    provider = aws.region-master
    name = "applicationlb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.sglb.id]
    subnets  = [aws_subnet.sub_public1.id,aws_subnet.sub_public2.id]
    tags = {
        Name = "application_lb"
    }
}

#create target group
resource "aws_lb_target_group" "tg-lb-task8" {
    provider = aws.region-master
    name = "tg-lb-task8"
    port = 80
    target_type = "instance"
    vpc_id = aws_vpc.vpc.id
    protocol = "HTTP"
    health_check {
        enabled = true
        interval = 10
        path = "/index.html"
        port = 80
        protocol = "HTTP"
        matcher = "200-299"
    }

}

#create listener
resource "aws_lb_listener" "listener-http" {
    provider = aws.region-master
    load_balancer_arn = aws_lb.application_lb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg-lb-task8.arn
    }
}

#attache instance with Targe group
resource "aws_lb_target_group_attachment" "attache_instance" {
    provider = aws.region-master
    target_group_arn = aws_lb_target_group.tg-lb-task8.arn
    target_id = aws_instance.web_server1.id
    port = 80

}


#------ SNS ---

#create SNS notification
resource "aws_sns_topic" "sns_notifications_topic" {
    name = "sns_notifications_topic"
}

#create SNS subscription
resource "aws_sns_topic_subscription" "sns_notifications_subscription" {
    topic_arn = aws_sns_topic.sns_notifications_topic.arn
    protocol = "email"
    endpoint = "cecilia_sandoval@epam.com"
}

#---- 
#create autoscaling notification
resource "aws_autoscaling_notification" "agsns_notifications" {
    group_names = [
    aws_autoscaling_group.AutoScalingGroupTask10.name]

    notifications = [
        "autoscaling:EC2_INSTANCE_LAUNCH",
        "autoscaling:EC2_INSTANCE_TERMINATE",
    ]

    topic_arn = aws_sns_topic.sns_notifications_topic.arn
}

#creeate template configuration
resource "aws_launch_configuration" "instance_config" {
    name = "web_config"
    image_id = var.ami-master
    instance_type = var.instance-type
}


#creeate autoscaling group
resource "aws_autoscaling_group" "AutoScalingGroupTask10" {
    name = "AutoScalingGroupTask10"
    max_size = 3
    min_size = 2
    health_check_grace_period = 30
    health_check_type  = "EC2"
    desired_capacity = 2
    force_delete = true
    launch_configuration = aws_launch_configuration.instance_config.name
    vpc_zone_identifier = [aws_subnet.sub_private1.id, aws_subnet.sub_private2.id]
    target_group_arns = [aws_lb_target_group.tg-lb-task8.arn]
    termination_policies = ["NewestInstance", "Default"]
    protect_from_scale_in = false

}

#creeate autoscaling policy Scale  out
resource "aws_autoscaling_policy" "ASGScalingUPPolicyHigh" {
    name = "ASGScalingUPPolicyHigh"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    #cooldown  = 300
    autoscaling_group_name = aws_autoscaling_group.AutoScalingGroupTask10.name
}

#creeate cloudwatch alarm CPU high
resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
    alarm_name  = "CPUAlarmHigh"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "70"
    #alarm_actions  = [aws_sns_topic.sns_notifications_topic.arn]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.AutoScalingGroupTask10.name
    }

    alarm_description = "This metric monitors ec2 cpu utilization"
    alarm_actions = [aws_autoscaling_policy.ASGScalingUPPolicyHigh.arn]
}

#creeate autoscaling policy Scale in
resource "aws_autoscaling_policy" "ASGScalingInPolicyDown" {
    name = "ASGScalingInPolicyDown"
    scaling_adjustment = 2
    adjustment_type = "ExactCapacity"
    #cooldown  = 300
    autoscaling_group_name = aws_autoscaling_group.AutoScalingGroupTask10.name
}

#creeate cloudwatch alarm CPU low
resource "aws_cloudwatch_metric_alarm" "CPUAlarmDowm" {
    alarm_name  = "CPUAlarmDowm"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "40"
    #alarm_actions  = [aws_sns_topic.sns_notifications_topic.arn]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.AutoScalingGroupTask10.name
    }

    alarm_description = "This metric monitors ec2 cpu utilization"
    alarm_actions = [aws_autoscaling_policy.ASGScalingInPolicyDown.arn]
}



