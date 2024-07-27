provider aws {
 region = var.region 
}
#///////////////////////////////////// Create Public Key ///////////////

resource "aws_key_pair" "bastion" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}
#/////////////////////////////////////Create VPC//////////////////////

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr[0].cidr_block
  enable_dns_support = var.vpc_cidr[0].dns_support
  enable_dns_hostnames = var.vpc_cidr[0].dns_hostnames
  tags = {
    Name = "group-4"
  }
}

#///////////////////////////////////Create Subnets////////////////////


resource "aws_subnet" "pb1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet[0].cidr
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = var.subnet[0].subnet_name
  }
}

resource "aws_subnet" "pb2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet[1].cidr
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = var.subnet[1].subnet_name
  }
}

resource "aws_subnet" "pb3" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet[2].cidr
  availability_zone = "${var.region}c"
  map_public_ip_on_launch = false
  tags = {
    Name = var.subnet[2].subnet_name
  }
}



#/////////////////////////////////Create Internet Gateway///////////////////////////

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.ing_name
  }
}

#//////////////////////////////////////Create Route Table/////////////////////////////

resource "aws_route_table" "pb_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = var.rt_names[0]
  }
}

#//////////////////////////////////////Route Table Association/////////////////////////

resource "aws_route_table_association" "pb1_a" {
  subnet_id      = aws_subnet.pb1.id
  route_table_id = aws_route_table.pb_rt.id
}

resource "aws_route_table_association" "pb2_a" {
  subnet_id      = aws_subnet.pb2.id
  route_table_id = aws_route_table.pb_rt.id
}

resource "aws_route_table_association" "pb3_a" {
  subnet_id      = aws_subnet.pb3.id
  route_table_id = aws_route_table.pb_rt.id
}

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


#///////////////////////////////////// Ouputs /////////////////////////////////////////////////
output "web_loadbalancer_url" {
  value = aws_lb.web.dns_name
}
