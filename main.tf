provider "aws" {
    region = "us-east-1"
}

# creating a vpc
resource "aws_vpc" "myapp-vpc"{
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
    enable_dns_support   = true
    enable_dns_hostnames = true
}

module "myapp-subnet"{
    source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    avail_zone = var.avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.myapp-vpc.id
    subnet_id = module.myapp-subnet.subnet.id
}

module "myapp-webserver"{
    source = "./modules/webserver"
    vpc_id = aws_vpc.myapp-vpc.id
    my_ip_address = var.my_ip_address
    env_prefix = var.env_prefix
    key_pair_id = var.key_pair_id
    image_id = var.image_id
    instance_type = var.instance_type
    avail_zone = var.avail_zone
    subnet_id = module.myapp-subnet.subnet.id
    
}