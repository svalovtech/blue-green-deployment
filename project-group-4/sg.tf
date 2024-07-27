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

