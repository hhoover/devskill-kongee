output "dns" {
  description = "Load Balancer DNS"
  value       = aws_lb.main.dns_name
}