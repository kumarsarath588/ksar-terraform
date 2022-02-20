terraform {
    required_version = ">= 1.1.6"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>4.2.0"
        }
    }
}

provider "aws" {
    profile = "default"
    region = var.region
}

resource "aws_instance" "ksar-mysql" {
    ami           = var.ami_id
    instance_type = var.instance_type
    security_groups = var.security_groups
    subnet_id = var.vpc_subnet_id
    key_name = var.keypair
    associate_public_ip_address = true

    connection {
        type     = "ssh"
        user     = "centos"
        private_key = file("/Users/saratkumar.k/calm-blueprints.key")
        host     = aws_instance.ksar-mysql.public_ip
    }

    provisioner "file" {
        source      = "scripts/centos_mysql_install.sh"
        destination = "/home/centos/centos_mysql_install.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /home/centos/centos_mysql_install.sh",
            "./centos_mysql_install.sh ${var.DB_NAME} ${var.DB_USER} ${var.DB_PASS}"
        ]
    }
}

resource "aws_instance" "ksar" {
    count = 2
    ami           = var.ami_id
    instance_type = var.instance_type
    security_groups = var.security_groups
    subnet_id = var.vpc_subnet_id
    key_name = var.keypair
    associate_public_ip_address = true

    tags = {
        Name  = "ksar-vm-${count.index + 1}"
    }

    connection {
        type     = "ssh"
        user     = "centos"
        private_key = file("/Users/saratkumar.k/calm-blueprints.key")
        host     = self.public_ip
    }

    provisioner "file" {
        source      = "artifacts/ksar"
        destination = "/home/centos/ksar"
    }

    provisioner "file" {
        source      = "artifacts/ksar.service"
        destination = "/home/centos/ksar.service"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /home/centos/ksar /usr/local/bin/ksar",
            "sudo mv /home/centos/ksar.service /etc/systemd/system/ksar.service",
            "chmod +x /usr/local/bin/ksar",
            "echo 'APP_DB_HOST=${aws_instance.ksar-mysql.private_ip}' | sudo tee /etc/environment",
            "echo 'APP_DB_USERNAME=${var.DB_USER}' | sudo tee -a /etc/environment",
            "echo 'APP_DB_PASSWORD=${var.DB_PASS}' | sudo tee -a /etc/environment",
            "echo 'APP_DB_PORT=${var.DB_PORT}' | sudo tee -a /etc/environment",
            "echo 'APP_DB_NAME=${var.DB_NAME}' | sudo tee -a /etc/environment",
            "sudo systemctl enable ksar && sudo systemctl start ksar",
        ]
    }
}

module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.17.0"

  name = "load-balancer-sg-dev"

  description = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id      = "vpc-0daf444033b10d505"

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.4.0"

  name     = "elb-ksar-dev"
  internal = false

  security_groups = [module.lb_security_group.this_security_group_id]
  subnets         = [var.vpc_subnet_id]

  number_of_instances = length(aws_instance.ksar)
  instances           = aws_instance.ksar[*].id

  listener = [{
    instance_port     = "8080"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  }]

  health_check = {
    target              = "HTTP:8080/health"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
  }
}
