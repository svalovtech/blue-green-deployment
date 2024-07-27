
data "aws_ami" "blue" {
  most_recent = true
   
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }
   filter {
    name   = "virtualization-type"
    values = ["hvm"]
}
owners = ["137112412989"]
}

resource "aws_instance" "blue-ec2" {
  count = var.enable_blue_env ? var.blue_instance_count : 0
  ami                    = data.aws_ami.blue.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.pb1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data_replace_on_change = true
  user_data = file("user-data-blue.sh")
  

  tags = {
    Name = "blue-group-4-${count.index}"
  }
}



#///////////////////////////////// Load Balancer Target Group Blue /////////////////////////////

resource "aws_lb_target_group" "blue-group" {
  name                 = "blue-target-group"
  vpc_id               = aws_vpc.vpc.id
  port                 = var.port[1]
  protocol             = "HTTP"
  
   health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    interval            = 10
    port                = var.port[1]
  }
  }
#/////////////////////////////////// Load Balancer Target Group Attachment Blue /////////////////

  resource "aws_lb_target_group_attachment" "blue" {
  count            = length(aws_instance.blue-ec2)
  target_group_arn = aws_lb_target_group.blue-group.arn
  target_id        = aws_instance.blue-ec2[count.index].id
  port             = var.port[1]
}

output ec2-blue {
    value = aws_instance.blue-ec2[*].id
}

