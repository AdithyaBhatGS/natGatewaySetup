output "print_subnet_ids" {
  value       = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
  description = "Outputs the list of subnet ids to the console"
}
