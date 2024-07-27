# terraform-blue-green-deployment

```hcl
module "group-4" {

                source               = "svalovtech/green-deployment/blue"
                version              = "1.0.0"
                region               = "us-east-2"
                traffic_distribution = "split"
                key_name             = "Bastion"
                ing_name             = "ing-group-4"
                rt_names             = [ "rt-group-4" ]
                instance_type        = "t2.micro"
                blue_instance_count  = 1
                green_instance_count = 1
                enable_blue_env      = true
                enable_green_env     = true

                port = [
                { from_port = 22, to_port = 22 },
                { from_port = 80, to_port = 80 }
                ]

                subnet = [
                { cidr = "192.168.1.0/24" ,subnet_name = "public1" },
                { cidr = "192.168.2.0/24" ,subnet_name = "public2" },
                { cidr = "192.168.3.0/24" ,subnet_name = "public3" }
                ]


                vpc_cidr = [
                    { cidr_block = "192.168.0.0/16" , dns_support = true , dns_hostnames = true
                
                } ]



}
```
