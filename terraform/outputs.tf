output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public_1a.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  value = try(aws_nat_gateway.this[0].id, null)
}

output "nat_eip_address" {
  value = try(aws_eip.nat[0].public_ip, null)
}

output "nat_eip_allocation_id" {
  value = try(aws_eip.nat[0].id, null)
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "security_group_ids" {
  value = {
    public_nat       = aws_security_group.public_nat.id
    private_compute  = aws_security_group.private_compute.id
    private_database = aws_security_group.private_database.id
  }
}
