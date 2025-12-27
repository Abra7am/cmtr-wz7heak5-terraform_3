output "vpc_id" {
  description = "The unique identifier of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block associated with the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "public_subnet_cidr_block" {
  description = "CIDR blocks of all public subnets"
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "public_subnet_availability_zone" {
  description = "Availability zones of all public subnets"
  value       = [for subnet in aws_subnet.public : subnet.availability_zone]
}

output "internet_gateway_id" {
  description = "The unique identifier of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "routing_table_id" {
  description = "The unique identifier of the routing table"
  value       = aws_route_table.this.id
}
