output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnets_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "ssm_test_instance_id" {
  value = aws_instance.ssm_test.id
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}
