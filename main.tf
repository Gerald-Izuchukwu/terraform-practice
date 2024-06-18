provider "aws" {
    region = "us-east-1"
}
variable avail_zone {}
variable vpc_cidr_block{}
variable subnet_cidr_block{}
variable env_prefix{}
variable my_ip_address{}
variable instance_type{}
variable my_public_key {}
variable image_id {}
variable key_pair_id{}
# creating a vpc
resource "aws_vpc" "myapp-vpc"{
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

# creating a subnet
resource "aws_subnet" "myapp-subnet-1"{
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name : "${var.env_prefix}-subnet-1"
    }
}

# creating a route-table
resource "aws_route_table" "myapp-routetable"{
    vpc_id = aws_vpc.myapp-vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags={
        Name: "${var.env_prefix}-rtb"
    }
}

# creating an IGW
resource "aws_internet_gateway" "myapp-igw"{
    vpc_id = aws_vpc.myapp-vpc.id
    tags={
        Name: "${var.env_prefix}-igw"
    }
}

# creating security group
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
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
        Name = "${var.env_prefix}-sg"
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

data "aws_key_pair" "ssh-key"{
    key_pair_id = var.key_pair_id
    # key_name = "test_key"
    # public_key = file(var.my_public_key)
}

output "key_pair_name"{
    value = data.aws_key_pair.ssh-key.key_name
}

resource "aws_instance" "myapp-server"{
    ami = var.image_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    # key_name = aws_key_pair.ssh-key.key_name
    key_name = data.aws_key_pair.ssh-key.key_name
    user_data = file("entry_script.sh")
    tags = {
        Name = "${var.env_prefix}-server"
    }
}

output "ec2_public_ip"{
    value = aws_instance.myapp-server.public_ip
}