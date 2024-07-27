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

 Create variables.tf

```hcl
variable region {
  type =string
}

variable rt_names {
  type = list(string)
}

variable ing_name {
  type = string
}

variable port {
 type = list(object({
  from_port = number
  to_port   = number
 }))
}

variable subnet {
  type = list(object({
    cidr = string
    subnet_name = string
  }))
}
variable instance_type {
  type =string
}

variable vpc_cidr {
    type = list(object({
      cidr_block = string
      dns_support = bool
      dns_hostnames = bool
    }))
  
}
variable key_name {
  type = string
}

variable "traffic_distribution" {
  description = "Levels of traffic distribution"
  type        = string
}

variable "enable_blue_env" {
  description = "Enable green environment"
  type        = bool
}

variable "blue_instance_count" {
  description = "Number of instances in green environment"
  type        = number
}

variable "enable_green_env" {
  description = "Enable green environment"
  type        = bool
}

variable "green_instance_count" {
  description = "Number of instances in green environment"
  type        = number
}
```
First, add the configuration for the local value and traffic distribution variable to variables.tf.

```hcl
locals {
  traffic_dist_map = {
    blue = {
      blue  = 100
      green = 0
    }
    blue-90 = {
      blue  = 90
      green = 10
    }
    split = {
      blue  = 50
      green = 50
    }
    green-90 = {
      blue  = 10
      green = 90
    }
    green = {
      blue  = 0
      green = 100
    }
  }
}
```



Notice that the local variable defines five traffic distributions. Each traffic distribution specifies the weight for the respective target group:

The blue target distribution is the current distribution — the load balancer routes 100% of the traffic to the blue environment, 0% to the green environment.

The blue-90 target distribution simulates canary testing. This canary test routes 90% of the traffic to the blue environment and 10% to the green environment.

The split target distribution builds on top of canary testing by increasing traffic to the green environment. This splits the traffic evenly between the blue and green environments (50/50).

The green-90 target distribution increases traffic to the green environment, sending 90% of the traffic to the green environment, 10% to the blue environment.

The green target distribution fully promotes the green environment — the load balancer routes 100% of the traffic to the green environment.

Modify the aws_lb_listener.app's default_action block in main.tf to match the following. The configuration uses lookup to set the target groups' weight. Notice that the configuration defaults to directing all traffic to the blue environment if no value is set.

```hcl
default_action {
    type             = "forward"


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
  ```
  Create backend.tf

  1.Create S3 bucket(TFSTATE.file) manualy and DynamoDB(LockID)

  2.Create file backend.tf  and configurate 

  ```hcl
  terraform {
  backend "s3" {
    bucket = "blue-green-deployment-group-4"
    key    = "ohio/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "state-lock"
  }
}
```
Create route53.tf(optinal)

```hcl
resource "aws_route53_record" "www" {
  zone_id = "Z09937073QW4Q0S20WQQ4"
  name = "www.devspro.net"
  type = "A"
  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }

}
```
Begin Blue-Green-Deployment Test

```hcl
terraform init

terraform apply

```



