provider "aws" {
	region = var.region
}

resource "aws_instance" "log_parser" {
	ami = var.ami_id
	instance_type = var.instance_type
	key_name = var.key_name
 	
	tags = {
		Name = "LogParserInstance"
}
	user_data = <<-EOF
	#!/bin/bash
	apt update -y
	apt install -y docker.io git
	systemctl start docker
	systemctl enable docker
	git clone https://github.com/Tiberiu18/log-parser-forwarder
	cd log-parser-forwarder
	docker-compose up -d
	EOF

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

