provider "aws" {
  region = var.region_var
}


resource "aws_vpc" "terraform_daniel_vpc_tf" {
  cidr_block           = "10.203.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = {
    Name = "terraform_daniel_vpc"
  }
}


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "terraform_daniel_subnet_webserver_tf" {
  vpc_id            = local.vpc_id_var
  cidr_block        = "10.203.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = {
    Name = "terraform_daniel_subnet_webserver"
  }
}


resource "aws_subnet" "terraform_daniel_subnet_webserver2_tf" {
  vpc_id            = local.vpc_id_var
  cidr_block        = "10.203.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = {
    Name = "terraform_daniel_subnet_webserver2"
  }
}

resource "aws_internet_gateway" "terraform_daniel_igw_tf" {
  vpc_id = local.vpc_id_var
  tags   = {
    Name = "terraform_daniel_igw"
  }
}


resource "aws_route_table" "terraform_daniel_rt_public_tf" {
  vpc_id = local.vpc_id_var

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_daniel_igw_tf.id
  }

  tags = {
    Name = "terraform_daniel_rt_public"
  }
}


resource "aws_route_table_association" "terraform_daniel_rt_assoc_public_webserver_tf" {
  subnet_id      = aws_subnet.terraform_daniel_subnet_webserver_tf.id
  route_table_id = aws_route_table.terraform_daniel_rt_public_tf.id
}

resource "aws_route_table_association" "terraform_daniel_rt_assoc_public_webserver2_tf" {
  subnet_id      = aws_subnet.terraform_daniel_subnet_webserver2_tf.id
  route_table_id = aws_route_table.terraform_daniel_rt_public_tf.id
}


resource "aws_network_acl" "terraform_daniel_nacl_webserver_public_tf" {
  vpc_id = local.vpc_id_var

  ingress {
    rule_no    = 100
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  ingress {
    rule_no    = 200
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  ingress {
    rule_no    = 10000
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }


  egress {
    rule_no    = 100
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  egress {
    rule_no    = 200
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  egress {
    rule_no    = 10000
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    action     = "allow"
  }

  subnet_ids = [
    aws_subnet.terraform_daniel_subnet_webserver_tf.id,
    aws_subnet.terraform_daniel_subnet_webserver2_tf.id
  ]

  tags = {
    Name = "terraform_daniel_nacl_webserver_public"
  }
}


resource "aws_security_group" "terraform_daniel_sg_webserver_tf" {
  name   = "terraform_daniel_sg_webserver"
  vpc_id = local.vpc_id_var

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform_daniel_sg_webserver"
  }
}


resource "aws_security_group" "terraform_daniel_sg_lb_tf" {
    name = "terraform_daniel_sg_lb"
    vpc_id = local.vpc_id_var

    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "terraform_daniel_sg_lb"
    }
}


resource "aws_lb" "terraform_daniel_lb_tf" {
  name               = "terraform-daniel-lb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            = [
    aws_subnet.terraform_daniel_subnet_webserver_tf.id,
    aws_subnet.terraform_daniel_subnet_webserver2_tf.id
  ]
  security_groups = [
    aws_security_group.terraform_daniel_sg_lb_tf.id
  ]

  tags = {
    Name = "terraform_daniel_lb"
  }
}

resource "aws_alb_target_group" "terraform_daniel_tg_tf" {
  name        = "terraform-daniel-tg"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = local.vpc_id_var
}


resource "aws_lb_listener" "terraform_daniel_lb_listener_tf" {
  load_balancer_arn = aws_lb.terraform_daniel_lb_tf.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.terraform_daniel_tg_tf.arn
  }
}

resource "aws_autoscaling_group" "terraform_daniel_asg_tf" {
  name = "terraform_daniel_asg"
  health_check_type = "ELB"
  health_check_grace_period = 120
  min_size = 2
  desired_capacity = 2
  max_size = 4
  vpc_zone_identifier = [
    aws_subnet.terraform_daniel_subnet_webserver_tf.id,
    aws_subnet.terraform_daniel_subnet_webserver2_tf.id
  ]
  target_group_arns = [aws_alb_target_group.terraform_daniel_tg_tf.arn]
  launch_template {
    id = aws_launch_template.terraform_daniel_lt_tf.id
  }

  metrics_granularity = "1Minute"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
}

resource "aws_autoscaling_policy" "terraform_daniel_asg_policy_tf" {
  name = "terraform_daniel_asg_policy"
  autoscaling_group_name = aws_autoscaling_group.terraform_daniel_asg_tf.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification{
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

data "template_file" "webserver_init" {
  template = file("./init-scripts/ec2_user_data.sh")
}

resource "aws_launch_template" "terraform_daniel_lt_tf" {
  name = "terraform_daniel_lt"
  image_id = var.amazon_linux_webserver_ami_id_var
  instance_type = var.instance_type_var
  key_name = var.key_name_var


  network_interfaces {
    associate_public_ip_address = true
    subnet_id = aws_subnet.terraform_daniel_subnet_webserver_tf.id
    security_groups = [aws_security_group.terraform_daniel_sg_webserver_tf.id]
    delete_on_termination = true
  }

user_data = base64encode(data.template_file.webserver_init.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "terraform_daniel_webserver"
    }
  }
}