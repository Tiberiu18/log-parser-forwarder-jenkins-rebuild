variable "region" {
	default = "eu-north-1"
}

variable "instance_type" {
	default = "t3.micro"
}

variable "key_name" {
	description = "AWS key pair name"
	default = "log-parser"
}

variable "ami_id" {
	description = "Ubuntu AMI ID"
	default = "ami-05d3e0186c058c4dd"
}
