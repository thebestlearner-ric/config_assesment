locals {
  ami_id = "ami-09e67e426f25ce0d7"
  vpc_id = "vpc-0c4b68f5524373824"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/home/geric/Desktop/learning/config_management/assessment/Demokey.pem"
}

provider "aws" {
  access_key = "ASIAVDKB23UVIYET7JPH"
  secret_key = "RVJKDVl06YPzistdAVRvSTo0hM3Lg32i0+w3J6bz"
  token = "FwoGZXIvYXdzED8aDIs4GqTOl/Cg8VJckyK3AQ/cFZj0ZR4kUWn1YU20vsxPZmOv+uIVDCS90qgVrkVmf0a5En+WOXOVedBvcio+czAmyZoiYbZiCaz7HAYJKieFEMZYOva28+vphaUavBVxoFLrjubBBq+ZYio6rDKdTXokOUVjsMJ+a11dbZ748pE5paiNE4rshe/T2qBoR5jDkfSlZLZr7uv5PJTiyKfhYVLRpfI43rZyIosoxrW+3h9FLC6xRrTX8kjIsjBymWbMUocUS0EtUCjvlqiXBjIt5DSpa+y1XeM94xMCoRsl8KjDR9kpaBwYOrAQ/fq/mYvNiE9LC/jQQK2Xe2Jl"
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
    command = "echo ${self.public_ip} > myhosts"
  }
  
  # provisioner "local-exec" {
  #   command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} varloop.yml"
  # }    
  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} ansible-wordpress/install-wordpress.yml -v"
  }
}

output "instance_ip" {
  value = aws_instance.web.public_ip
}