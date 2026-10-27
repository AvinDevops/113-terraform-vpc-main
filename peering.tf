## creating peering ##
resource "aws_vpc_peering_connection" "peering" {
    count = var.is_peering_required ? 1 : 0
    vpc_id = aws_vpc.main.id #requestor
    peer_vpc_id = var.acceptor_vpc_id == "" ? data.aws_vpc.default.id : var.acceptor_vpc_id #acceptor
    auto_accept = var.acceptor_vpc_id == "" ? true : false

    tags = merge(
        var.common_tags,
        var.vpc_peering_tags,
        {
            Name = local.resource_name
        }
    )

}

## creating routes ##
#count is useful to control when resource is required#
# public #
resource "aws_route" "public_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
    route_table_id = aws_route_table.public.id
    destination_cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

# private #
resource "aws_route" "private_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1: 0
    route_table_id = aws_route_table.private.id
    destination_cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

# database #
resource "aws_route" "database_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
    route_table_id = aws_route_table.database.id
    destination_cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

# main #
resource "aws_route" "main_peering" {
    count = var.is_peering_required && var.acceptor_vpc_id == "" ? 1 : 0
    route_table_id = data.aws_route_table.default_main.id
    destination_cidr_block = var.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

