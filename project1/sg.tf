resource "aws_security_group" "allow_tls" {
  vpc_id = aws_vpc.vpc.id
  name        = "group-4"
  description = "Allow TLS inbound traffic"

    ingress {
    description      = "TLS from VPC"
    from_port        = var.port[0]
    to_port          = var.port[0]
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "TLS from VPC"
    from_port        = var.port[1]
    to_port          = var.port[1]
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
} 

