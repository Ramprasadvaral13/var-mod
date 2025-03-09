resource "aws_vpc" "demo-vpc" {
    cidr_block = var.vpc-cidr
    enable_dns_support = true
    enable_dns_hostnames = true
  
}

resource "aws_internet_gateway" "demo-igw" {
    vpc_id = aws_vpc.demo-vpc.id
  
}

resource "aws_subnet" "demo-subnet" {
    vpc_id = aws_vpc.demo-vpc.id
    for_each = var.subnet
    cidr_block = each.value.cidr
    availability_zone = each.value.az
    map_public_ip_on_launch = each.value.ip
}

resource "aws_route_table" "demo-public-route" {
    vpc_id = aws_vpc.demo-vpc.id
    route{
        cidr_block = var.route-cidr
        gateway_id = aws_internet_gateway.demo-igw.id
    }
  
}

resource "aws_route_table_association" "demo-public-rtba" {
    route_table_id = aws_route_table.demo-public-route.id
    for_each = {for key, subnet in var.subnet : key => subnet if subnet.ip == true }
    subnet_id = aws_subnet.demo-subnet[each.key].id
  
}

resource "aws_eip" "demo-eip" {
    domain = "vpc"
  
}

resource "aws_nat_gateway" "demo-nat" {
    allocation_id = aws_eip.demo-eip.id
    subnet_id = aws_subnet.demo-subnet["public 1"].id
  
}

resource "aws_route_table" "demo-private-route" {
    vpc_id = aws_vpc.demo-vpc.id
    route {
        cidr_block = var.route-cidr
        nat_gateway_id = aws_nat_gateway.demo-nat.id
    }
  
}

resource "aws_route_table_association" "demo-private-rtba" {
    route_table_id = aws_route_table.demo-private-route.id
    subnet_id = {for kwy, subnet in var.subnet : key => subnet if subnet.ip == false }
  
}