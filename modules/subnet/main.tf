# creating a subnet
resource "aws_subnet" "myapp-subnet-1"{
    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name : "${var.env_prefix}-subnet-1"
    }
}

# creating a route-table
resource "aws_route_table" "myapp-routetable"{
    vpc_id = var.vpc_id
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
    vpc_id = var.vpc_id
    tags={
        Name: "${var.env_prefix}-igw"
    }
}