locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-07553a83676d7957d"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/home/geric/Desktop/learning/config_management/assessment/Demokey.pem"
}



provider "aws" {
  access_key = "ASIAVDKB23UVKNNGUTDN"
  secret_key = "4Jt2s3RBngsBScTj1cfJMVrF5gvCkqAk3YniOgkU"
  token = "FwoGZXIvYXdzEFMaDDZxnczNF2uD8ai+fyK3AcNAIyJcL4ICV+TvBXWXnyXELlqOl7QHSUsHg/9N3ohl7CtEQ6aVNxSPebIsukNfNR05dpp0qHjBrYz0bw63wvwUg6cpToyQqSfYBiFpUaa0NnItgeXCkc5BJKFyt/JyJn7ILBB6nSFQS16bbmBXiTCT9UQ9z1YYth6QAtvgaDZtLH7SnkJERMY8Ncx91HQHjgHR3h4w4tJifxmq5+pQpRMF6o/coQh6VA3Jbv5WGmBSmrit0Ljo2ii+z6yXBjItr2LZ+49QHbZWIQsVx6/xSOEhysY9ndcsaowU8GAm9z2XMXcY3papNr0Wffnf"
  region = "us-east-1"
}

resource "aws_security_group" "demoaccess" {
  name = "demoaccess"
  vpc_id = local.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
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

resource "aws_instance" "web" {
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    Name = "Demo test"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }
	provisioner "remote-exec" {
    inline = [
      "echo 'Wait for SSH connection...'"
    ]
  }
  provisioner "local-exec" {
    command = "echo '[wordpress]' > ansible-wordpress/production && echo ${self.public_ip} >> ansible-wordpress/production"
  }
  provisioner "local-exec" {
  	command = "echo '[wordpress]' > myhosts && echo ${self.public_ip} >> myhosts"
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} varloop.yml -v"
  }    
  provisioner "local-exec" {
    #command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} ansible-wordpress/install-wordpress.yml -v"
		command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} wordpress-demo/playbook.yml -v"
  }
}

output "instance_ip" {
  value = aws_instance.web.public_dns
}