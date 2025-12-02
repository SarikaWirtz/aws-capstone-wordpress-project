# # IAM role & instance profile for EC2 (SSM + ability to read from S3 if needed)
# resource "aws_iam_role" "ec2_role" {
#   name = "ec2-wordpress-role"
#   assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
# }

# data "aws_iam_policy_document" "ec2_assume_role" {
#   statement {
#     effect = "Allow"
#     principals {
#       type = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role_policy_attachment" "ssm" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "ec2-wordpress-profile"
#   role = aws_iam_role.ec2_role.name
# }
