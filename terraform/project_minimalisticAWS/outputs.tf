output "instance_public_ip" {
	description = "Public IP of the EC2 Instance"
	value = aws_instance.log_parser.public_ip
}
