locals {
  ami_id = "ami-0729e439b6769d6ab" # using Ubuntu 18.04 LTS
  vpc_id = "vpc-050bc5d5c4963fa89"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/home/geric/Desktop/learning/config_management/assessment/Demokey.pem"
}



provider "aws" {
  access_key = "ASIAVDKB23UVM5FMDDOU"
  secret_key = "TMILw0iopA3NsNCibzRpBtJue7YRv4j33LObZ2S+"
  token = "FwoGZXIvYXdzEGsaDC2+dpPlTiV5oZkFpCK3AbBN9r8dtpuPiEQSE522gv3ODTpMNSnbh4Q3g4ai6waZXQNoqXCe9FoPiG4AybB+v0tcTU37/xIvOe1dZnHCIeX6JY/fNZZAR1yrpAci4qKU8yAdZo5L+fHa6/MHMO4qkogYT68JSfpDyUBuLWJSTUz76QOqXpHY6t2Vz3W5dQoT9boXXpVvDKnO38IHfSyfoO5LCLgUOXgIzYNRL3el/+jUkxKFEzG48BBhJUQu9t4FAAtMReRrSSjI9LGXBjItkAWtzghXmt+7OCeQ/i1NJOCSjHypYI/IU0GH4aMQVWS2KrOPQ2Kn1jQFKUhA"
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
    command = "echo '[wordpress]\\n${self.public_ip}' | tee myhosts ansible-wordpress/production wordpress-demo/hosts"
    # && echo ${self.public_ip} | tee myhosts ansible-wordpress/production wordpress-demo/hosts"
  }
  #provisioner "local-exec" {
  #	command = "echo '[wordpress]' > myhosts && echo ${self.public_ip} >> myhosts"
  #}
  #provisioner "local-exec" {
  #  command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} varloop.yml -v"
  #}    
  provisioner "local-exec" {
    #command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} ansible-wordpress/install-wordpress.yml -v"
		#command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} wordpress-demo/playbook.yml -v"
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} ansible-playbooks/wordpress-lamp_ubuntu1804/playbook.yml"
  }
}

output "instance_ip" {
  value = aws_instance.web.public_dns
}