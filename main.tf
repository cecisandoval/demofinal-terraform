terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "~> 4.16"
        }
    }
    
    required_version = ">= 1.2.0"

}

# Create VPC
resource "aws_vpc" "vpc"{
    provider = aws.region-master
    cidr_block = "192.168.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "Task8-vpc"
    }

}

#Create IG
resource "aws_internet_gateway" "igw" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
}

#Get available AZs in VPC for region
data "aws_availability_zones" "azs" {
    provider = aws.region-master
    state = "available"
}

#Create subnet private 1
resource "aws_subnet" "sub_private1" {
    provider = aws.region-master
    availability_zone = element(data.aws_availability_zones.azs.names, 0)
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.1.0/26"
    tags = {
        Name = "sub_private1_task8"
    }

}

#Create subnet private 2
resource "aws_subnet" "sub_private2" {
    provider = aws.region-master
    availability_zone = element(data.aws_availability_zones.azs.names, 1)
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.2.0/26"
    tags = {
        Name = "sub_private2_task8"
    }

}


#Create subnet private MySQL 1
resource "aws_subnet" "sub_privatemsql1" {
    provider = aws.region-master
    availability_zone = element(data.aws_availability_zones.azs.names, 0)
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.5.0/26"
    tags = {
        Name = "sub_privatemsql1"
    }

}

#Create subnet private MySQL 1
resource "aws_subnet" "sub_privatemsql2" {
    provider = aws.region-master
    availability_zone = element(data.aws_availability_zones.azs.names, 1)
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.6.0/26"
    tags = {
        Name = "sub_privatemsql2"
    }

}


#Create subnet public 1
resource "aws_subnet" "sub_public1" {
    provider = aws.region-master
    availability_zone = element(data.aws_availability_zones.azs.names, 0)
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.3.0/26"
    tags = {
        Name = "sub_public1_task8"
    }

}

#Create subnet public 2
resource "aws_subnet" "sub_public2" {
    availability_zone = element(data.aws_availability_zones.azs.names, 1)
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.4.0/26"
    tags = {
        Name = "sub_public2_task8"
    }

}

#SG MySQL
resource "aws_security_group" "sgmsql" {

    provider = aws.region-master
    name = "sgmsql"
    description = "sg-msql"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "Allow port 3306"
        from_port  = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}



#SG LB
resource "aws_security_group" "sglb" {

    provider = aws.region-master
    name = "SGLB"
    description = "SGLB"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "Allow port 80"
        from_port  = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


#SG web server
resource "aws_security_group" "sgw" {
    provider = aws.region-master
    name = "SGWebServer"
    description = "SGWebServer"
    vpc_id = aws_vpc.vpc.id
    ingress {
        description = "Allow port ssh"
        from_port  = 22
        to_port = 22
        protocol = "tcp"
        #security_groups = [aws_security_group.sglb.id]
        cidr_blocks = ["0.0.0.0/0"]
    }  
    ingress {
        description = "Allow port 80"
        from_port  = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.sglb.id]
        #cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

#Create route table Public Internet
resource "aws_route_table" "internet_route" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    lifecycle {
        ignore_changes = all
    }
    tags = {
        Name = "Internet-RoutTable"
    }
}

#Associate public sub 1 to RT
resource "aws_route_table_association" "set_subnets1" {
    provider = aws.region-master
    subnet_id = aws_subnet.sub_public1.id
    route_table_id = aws_route_table.internet_route.id
}

#Associate public sub 2 to RT
resource "aws_route_table_association" "set_subnets2" {
    provider = aws.region-master
    subnet_id = aws_subnet.sub_public2.id
    route_table_id = aws_route_table.internet_route.id
}

#Associate Main RT to Internte RT
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
    route_table_id = aws_route_table.internet_route.id
}

#Create route table Private subnets1
resource "aws_route_table" "private_rout1" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
    #route {
        #cidr_block = "0.0.0.0/0"
        #gateway_id = aws_internet_gateway.igw.id
    #}
    lifecycle {
        ignore_changes = all
    }
    tags = {
        Name = "private-RoutTable1"
    }
}


#Create route table Private subnets2
resource "aws_route_table" "private_rout2" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
    #route {
        #cidr_block = "0.0.0.0/0"
        #gateway_id = aws_internet_gateway.igw.id
    #}
    lifecycle {
        ignore_changes = all
    }
    tags = {
        Name = "private-RoutTable2"
    }
}

#Create route table Private MsQL subnets1
resource "aws_route_table" "privatemsql_route1" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
    lifecycle {
        ignore_changes = all
    }
    tags = {
        Name = "privatemsql_route1"
    }
}

#Create route table Private MsQL subnets2
resource "aws_route_table" "privatemsql_route2" {
    provider = aws.region-master
    vpc_id = aws_vpc.vpc.id
    lifecycle {
        ignore_changes = all
    }
    tags = {
        Name = "privatemsql_route2"
    }
}

#Associate private sub MySQL 1 to RTprivate1
resource "aws_route_table_association" "set_subnetsmsql1private" {
    provider = aws.region-master
    subnet_id = aws_subnet.sub_privatemsql1.id
    route_table_id = aws_route_table.privatemsql_route1.id
}


#Associate private sub MySQL 2 to RTprivate2
resource "aws_route_table_association" "set_subnetsmsql2private" {
    provider = aws.region-master
    subnet_id = aws_subnet.sub_privatemsql2.id
    route_table_id = aws_route_table.privatemsql_route2.id
}


#Associate private sub 1 to RTprivate1
resource "aws_route_table_association" "set_subnets1private" {
    provider = aws.region-master
    subnet_id = aws_subnet.sub_private1.id
    route_table_id = aws_route_table.private_rout1.id
}

#Associate private sub 1 to RTprivate2
resource "aws_route_table_association" "set_subnets2private" {
    provider = aws.region-master
    subnet_id = aws_subnet.sub_private2.id
    route_table_id = aws_route_table.private_rout2.id
}






