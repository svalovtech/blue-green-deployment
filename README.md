# terraform-blue-green-deployment
Overview
Blue green deployment is an application release model that gradually transfers user traffic from a previous version of an app or microservice to a nearly identical new release—both of which are running in production. 

The old version can be called the blue environment while the new version can be known as the green environment. Once production traffic is fully transferred from blue to green, blue can standby in case of rollback or pulled from production and updated to become the template upon which the next update is made.

Blue-Green Deployment Background
In a blue-green deployment, the current service deployment acts as the blue environment. When you are ready to release an update, you deploy the new service version and underlying infrastructure into a new green environment. After verifying the green deployment, you redirect traffic from the blue environment to the green one.

This workflow lets you:

Test the green environment and identify any errors before promoting it. Your configuration still routes traffic to the blue environment while you test, ensuring near-zero downtime.
Easily roll back to the previous deployment in the event of errors by redirecting all traffic back to the blue environment.

Review example configuration
  Clone your repository

            $ git clone your url from GitHub(ssh)

Navigate to the repository directory in your terminal.

            $ cd ..

This repository contains multiple Terraform configuration files:

    1.main.tf defines the Provider,Public Key,VPC, Security Groups, Load Balancers and Balancer Listener

    2.variables.tf defines variables used by the configuration such as region, CIDR blocks, number of subnets, etc.

    3.ec2-blue.tf defines  AWS instances that run a user data script to start a web server. These instances represent "version 1.0" of the example service.

    4.ec2-blue.tf defines  AWS instances that run a user data script to start a web server. These instances represent "version 1.0" of the example service.

    5.user-data-blue.sh contains the script to start the web server blue.

    6.user-data-green.sh contains the script to start the web server green.
    7.terraform.tfvars defines the terraform block, which specifies the Terraform binary and AWS provider versions.

    8.sg.tf   Is the resource type for AWS security groups.

    9.route53.tf Define and manage DNS settings using Amazon Route 53, which is a scalable and highly available Domain Name System (DNS) web service provided by AWS (Amazon Web Services).

    10.backend  Define how and where Terraform's state data is stored.

    11.  .terraform.lock.hcl is the Terraform dependency lock file.



Review main.tf and sg.tf
Open main.tf. This file uses the AWS provider to deploy the base infrastructure for this tutorial, public key, including a VPC, subnets, Route Table , Route Table Association,  an application security group, and a load balancer security group.

The configuration defines an   <aws_lb> resource which represents an ALB. When the load balancer receives the request, it evaluates the listener rules, defined by <aws_lb_listener.http>, and routes traffic to the appropriate target group.


```hcl
#///////////////////////////////// Load Balancer //////////////////////////////////////////

resource "aws_lb" "web" {
  name               = "lb-group-4"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets            = [aws_subnet.pb1.id ,aws_subnet.pb2.id ,aws_subnet.pb3.id]
  internal           = false
}





#/////////////////////////////////// Load Balancer Listener /////////////////////////////////////

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = var.port[1].from_port
  protocol          = "HTTP"

 
default_action {
    type             = "forward"
# target_group_arn =aws_lb_target_group.blue-group.arn

      forward {
        target_group {
          arn    = aws_lb_target_group.blue-group.arn
          weight = lookup(local.traffic_dist_map[var.traffic_distribution], "blue", 100)
        }

        target_group {
          arn    = aws_lb_target_group.green-group.arn
          weight = lookup(local.traffic_dist_map[var.traffic_distribution], "green", 0)
        }

        stickiness {
          enabled  = false
          duration = 1
        }
      }
	  
  }
}
```

sg.tf
```hcl
resource "aws_security_group" "allow_tls" {
  vpc_id = aws_vpc.vpc.id
  name        = "group-4"
  description = "Allow TLS inbound traffic"

    dynamic ingress {
    for_each         = var.port
    content {
    description      = "TLS from VPC"
    from_port        = ingress.value.from_port
    to_port          = ingress.value.to_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

    

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
} 
```



Review ec2-blue.tf and ec2-green.tf
Open ec2-blue.tf. This configuration defines  AWS instance that start web server, which return the text Version 1.0 . This represents the sample application's first version and indicates which server responded to the request.

```hcl
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
```
This file also defines the blue load balancer target group and attaches the blue instances to it using aws_lb_target_group_attachment.

```hcl
#///////////////////////////////// Load Balancer Target Group Blue /////////////////////////////

resource "aws_lb_target_group" "blue-group" {
  name                 = "blue-target-group"
  vpc_id               = aws_vpc.vpc.id
  port                 = var.port[1].from_port
  protocol             = "HTTP"
  
   health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    interval            = 10
    port                = var.port[1].from_port
  }
  }
#/////////////////////////////////// Load Balancer Target Group Attachment Blue /////////////////

  resource "aws_lb_target_group_attachment" "blue" {
  count            = length(aws_instance.blue-ec2)
  target_group_arn = aws_lb_target_group.blue-group.arn
  target_id        = aws_instance.blue-ec2[count.index].id
  port             = var.port[1].from_port
}
```

Open ec2-green.tf. This configuration defines  AWS instance that start web server, which return the text Version 2.0 . This represents the sample application's second version and indicates which server responded to the request.

```hcl
data "aws_ami" "green" {
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

resource "aws_instance" "green-ec2" {
    count = var.enable_blue_env ? var.blue_instance_count : 0
  ami           = data.aws_ami.green.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.pb2.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data_replace_on_change = true
  user_data = file("user-data-green.sh")

  tags = {
    Name = "green-group-4-${count.index}"
  }
}
```
This file also defines the green load balancer target group and attaches the green instances to it using aws_lb_target_group_attachment.

```hcl
#///////////////////////////////// Load Balancer Target Group Green /////////////////////////////

resource "aws_lb_target_group" "green-group" {
  name                 = "green-target-group"
  vpc_id               = aws_vpc.vpc.id
  port                 = var.port[1].from_port
  protocol             = "HTTP"
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    interval            = 10
    port                = var.port[1].from_port
  }
}

#/////////////////////////////////// Load Balancer Target Group Attachment Green /////////////////

resource "aws_lb_target_group_attachment" "green" {
  count            = length(aws_instance.green-ec2)
  target_group_arn = aws_lb_target_group.green-group.arn
  target_id        = aws_instance.green-ec2[count.index].id
  port             = var.port[1].from_port
}
```
