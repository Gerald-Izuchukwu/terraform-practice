provider "aws" {
    region = "us-east-1"
}
variable avail_zone {}
variable vpc_cidr_block{}
variable subnet_cidr_block{}
variable env_prefix{}
variable my_ip_address{}
variable instance_type{}
variable public_key {}
variable image_id {}
variable key_pair_id{}

# creating a vpc
resource "aws_vpc" "this"{
    cidr_block = var.vpc_cidr_block
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name: "${var.env_prefix}_vpc"
    }
}

# creating a subnet
resource "aws_subnet" "public"{
    count = 1

    vpc_id = aws_vpc.this.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    map_public_ip_on_launch = true

    tags = {
        Name : "${var.env_prefix}_subnet-1"
    }

}

# creating a route-table
resource "aws_route_table" "public"{
    count = 1

    vpc_id = aws_vpc.this.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this[0].id
    }

    tags={
        Name: "${var.env_prefix}_rtb"
    }
    
}

# creating an IGW
resource "aws_internet_gateway" "this"{
    count = 1

    vpc_id = aws_vpc.this.id

    tags={
        Name: "${var.env_prefix}_igw"
    }
}

resource "aws_route_table_association" "public_route_table_association" {
#   count          = length(var.availability_zones)
#   subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

# creating security group
resource "aws_security_group" "this" {
    name = "myapp-sg"
    vpc_id = aws_vpc.this.id
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip_address]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    
    tags = {
        Name = "${var.env_prefix}_sg"
    }
}

# data "aws_ami" "latest-amazon-linux-image"{
#     most_recent = true
#     owners = ["137112412989"]
#     filter  {
#         name = "name"
#         values = ["al2023-ami-*-x86-64"]
#     }

#     filter  {
#         name = "virtualization-type"
#         values = ["hvm"]
#     }
# }

resource "aws_key_pair" "ssh_key"{
    # key_pair_id = var.key_pair_id
    key_name = "test_key_id_rsa"
    public_key = file(var.public_key)
}

output "key_pair_name"{
    value = aws_key_pair.ssh_key.key_name
}

resource "aws_instance" "this"{
    count = 1

    ami = var.image_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_security_group.this.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    # key_name = aws_key_pair.ssh-key.key_name
    key_name = aws_key_pair.ssh_key.key_name
    user_data = file("entry_script.sh")

    tags = {
        Name = "${var.env_prefix}_server"
    }
}

output "ec2_public_ip"{
    value = aws_instance.this[0].public_ip
}