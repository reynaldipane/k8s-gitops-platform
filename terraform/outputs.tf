output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnets_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}

output "control_plane_id" {
  value = aws_instance.control_plane.id
}

output "worker_ids" {
  value = { for name, w in aws_instance.worker : name => w.id }
}