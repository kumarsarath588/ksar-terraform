resource "aws_instance" "aws-mysql" {
    ami           = var.ami_id
    instance_type = var.instance_type
    security_groups = var.security_groups
    subnet_id = var.vpc_subnet_id
    key_name = var.keypair
    associate_public_ip_address = true

    connection {
        type     = "ssh"
        user     = "centos"
        private_key = file("./private.key")
        host     = aws_instance.aws-mysql.public_ip
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