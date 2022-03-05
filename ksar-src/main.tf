provider "aws" {
    profile = "default"
    region = var.region
}

module "mysql" {
    source          = "./modules/aws-mysql"

    ami_id          = var.ami_id
    instance_type   = var.instance_type
    security_groups = [var.security_groups]
    vpc_subnet_id   = var.vpc_subnet_id
    keypair         = var.keypair
    DB_NAME         = var.DB_NAME
    DB_USER         = var.DB_USER
    DB_PASS         = var.DB_PASS

}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.17.0"

  name        = "ksar-web-server-sg"
  description = "Security group for web-servers with HTTP ports open within VPC"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_instance" "ksar" {
    count           = var.ksar_instance_count
    ami             = var.ami_id
    instance_type   = var.instance_type
    security_groups = [module.app_security_group.this_security_group_id, var.security_groups]
    subnet_id       = var.vpc_subnet_id
    key_name        = var.keypair
    associate_public_ip_address = true

    tags = {
        Name  = "ksar-vm-${count.index + 1}"
    }

    connection {
        type        = "ssh"
        user        = "centos"
        private_key = file("./private.key")
        host        = self.public_ip
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
            "echo 'APP_DB_HOST=${module.mysql.mysql_private_ip_address}' | sudo tee /etc/environment",
            "echo 'APP_DB_USERNAME=${var.DB_USER}' | sudo tee -a /etc/environment",
            "echo 'APP_DB_PASSWORD=${var.DB_PASS}' | sudo tee -a /etc/environment",
            "echo 'APP_DB_PORT=${var.DB_PORT}' | sudo tee -a /etc/environment",
            "echo 'APP_DB_NAME=${var.DB_NAME}' | sudo tee -a /etc/environment",
            "sudo systemctl enable ksar && sudo systemctl start ksar",
        ]
    }
}

resource "random_string" "lb_id" {
  length  = 4
  special = false
}

module "lb_security_group" {
  source          = "terraform-aws-modules/security-group/aws//modules/web"
  version         = "3.17.0"

  name            = "load-balancer-sg-dev"

  description     = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id          = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "elb_http" {
  source          = "terraform-aws-modules/elb/aws"
  version         = "3.0.1"

  name            = trimsuffix(substr(join("-", ["elb-ksar-dev", random_string.lb_id.result]), 0, 32), "-")
  internal        = false

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
