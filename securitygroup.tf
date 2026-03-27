# --- Security Groups (Use Existing) ---

data "aws_security_group" "alb_sg" {
  id = var.alb_security_group_id
}

data "aws_security_group" "instance_sg" {
  id = var.instance_security_group_id
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = data.aws_security_group.alb_sg.id
}

output "instance_security_group_id" {
  description = "The ID of the instance security group"
  value       = data.aws_security_group.instance_sg.id
}
