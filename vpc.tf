## vpc ##
resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    instance_tenancy = "default"
    enable_dns_hostnames = var.enable_dns_hostnames

    tags = merge(
        var.common_tags,
        var.vpc_tags,
        {
            Name = local.resource_name #expense-dev
        }
    )
}

## igw ##
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.igw_tags,
        {
            Name = local.resource_name
        }
    )
}

## public subnet ##
resource "aws_subnet" "public_subnet" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = local.az_names[count.index]
    map_public_ip_on_launch = true

    tags = merge (
        var.common_tags,
        var.public_subnet_tags,
        {
            Name = "${local.resource_name}-public-${local.az_names[count.index]}"
        }
    )
}

## private subnet ##
resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = local.az_names[count.index]

    tags = merge (
        var.common_tags,
        var.private_subnet_tags,
        {
            Name = "${local.resource_name}-private-${local.az_names[count.index]}"
        }
    )

}

## database subnet ##
resource "aws_subnet" "database_subnet" {
    count = length(var.database_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidrs[count.index]
    availability_zone = local.az_names[count.index]

    tags = merge (
        var.common_tags,
        var.database_subnet_tags,
        { 
            Name = "${local.resource_name}-database-${local.az_names[count.index]}"
        }
    )
}

resource "aws_db_subnet_group" "default" {
    name = local.resource_name
    subnet_ids = aws_subnet.database_subnet[*].id

    tags = merge(
        var.common_tags,
        var.database_subnet_group_tags,
        {
            Name = local.resource_name
        }
    )
}

## eip ##
resource "aws_eip" "expense" {
    domain = "vpc"
}

## nat gateway ##
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.expense.id
    subnet_id = aws_subnet.public_subnet[0].id

    tags = merge (
        var.common_tags,
        var.nat_tags,
        {
            Name = "${local.resource_name}-nat"
        }
    )

    depends_on = [aws_internet_gateway.gw]
}

### Route Tables ###
## public route table ##
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.public_route_table_tags,
        {
            Name = "${local.resource_name}-public"
        }
    )
}

## private route table ##
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.private_route_table_tags,
        {
            Name = "${local.resource_name}-private"
        }
    )
}

## database route table ##
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.common_tags,
        var.database_route_table_tags,
        {
            Name = "${local.resource_name}-database"
        }
    )
}

### Adding Routes ###
## public route ##
resource "aws_route" "public_route" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
}

## private route ##
resource "aws_route" "private_route_nat" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
}

## database route ##
resource "aws_route" "database_route_nat" {
    route_table_id = aws_route_table.database.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
}


### Route Table Associations ###
## public subnet association ##
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public.id
}

## private subnet association ##
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
    subnet_id = element(aws_subnet.private_subnet[*].id,count.index)
    route_table_id = aws_route_table.private.id
}

## database subnet association ##
resource "aws_route_table_association" "database" {
    count = length(var.database_subnet_cidrs)
    subnet_id = element(aws_subnet.database_subnet[*].id,count.index)
    route_table_id = aws_route_table.database.id
}