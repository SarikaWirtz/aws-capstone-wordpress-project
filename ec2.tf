# Get the latest Amazon Linux 2 AMI

# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners      = ["137112412989"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*"]
#   }
# }

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1*"]
  }
}

# Creating Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.aws_instance_type_t2micro
  availability_zone      = var.aws_availability_zone_a
  vpc_security_group_ids = [aws_security_group.aws_ssh_sg.id]
  subnet_id              = aws_subnet.public_subnet_1.id
  key_name               = "vockey" # Create new key if using different region than us-west-2
  user_data              = file("bastion-userdata.sh")
  tags = {
    Name = "AwsCapstoneBastionHost"
  }
}


# Create Web Server Instance in Public Subnet 1
# resource "aws_instance" "web_server" {
#   ami                    = data.aws_ami.amazon_linux_2023.id
#   instance_type          = var.aws_instance_type_t2micro
#   availability_zone      = var.aws_availability_zone_a
#   vpc_security_group_ids = [aws_security_group.aws_ssh_sg.id, aws_security_group.aws_webserver_sg.id]
#   subnet_id              = aws_subnet.public_subnet_1.id
#   key_name               = "vockey" # Create new key if using different region than us-west-2
#   user_data              = templatefile("${path.module}/userdata.sh", {
#     db_name        = var.db_name
#     username       = var.username
#     password       = var.password
#     DBRootPassword = var.DBRootPassword
#     rds_endpoint   = aws_db_instance.mysql.endpoint
#   })
#   tags = {
#     Name = "AwsCapstoneWebServer"
#   }
# }

