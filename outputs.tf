# output "azs" {
#     value = data.aws_availability_zones.available.names
# }

output "vpc_id" {
    value = aws_vpc.main.id
}

# output "default_vpc" {
#     value = data.aws_vpc.default.id
# }

output "public_subnet_ids" {
    value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
    value = aws_subnet.private_subnet[*].id
}

output "database_subnet_ids" {
    value = aws_subnet.database_subnet[*].id
}

output "database_subnet_group_id" {
    value = aws_db_subnet_group.default.id
}