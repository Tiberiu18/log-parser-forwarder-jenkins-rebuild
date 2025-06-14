provider "aws" {
	region = "eu-north-1"
}

resource "aws_instance" "log_parser" {
	ami = "ami-05d3e0186c058c4dd"
	instance_type = "t3.micro"
	key_name = "log-parser"
 	
	tags = {
		Name = "LogParserInstance"
}

vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}

resource "aws_security_group" "allow_ssh" {
	name_prefix = "ssh-allow-"

	ingress {
		description = "Allow SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]

}

}

output "public_ip" {
	value = aws_instance.log_parser.public_ip

}

