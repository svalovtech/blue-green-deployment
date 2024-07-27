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
 type = list 
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



#///// terraform apply -var 'traffic_distribution=green'
#///// for i in `seq 1 10`; do curl <Your url lb output>; done