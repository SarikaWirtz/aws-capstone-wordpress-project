# EFS
resource "aws_efs_file_system" "efs" {
  creation_token = "wordpress-efs-token"
  tags = { 
    Name = "wordpress-efs" 
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  for_each = {
    subnet1 = aws_subnet.private_subnet_1.id
    subnet2 = aws_subnet.private_subnet_2.id
  }
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

# Outputs
output "efs_id" { value = aws_efs_file_system.efs.id }
output "efs_dns_name" {
  value = aws_efs_file_system.efs.dns_name
}
