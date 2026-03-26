# --- Security Groups ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-${var.env_name}-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.env_name}-alb-sg"
    Environment = var.env_name
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.app_name}-${var.env_name}-instance-sg"
  description = "Allow traffic from ALB SG to EB instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.env_name}-instance-sg"
    Environment = var.env_name
  }
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "instance_security_group_id" {
  description = "The ID of the instance security group"
  value       = aws_security_group.instance_sg.id
}
