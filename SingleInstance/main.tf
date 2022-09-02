resource "aws_key_pair" "LAMPkey" {
  key_name   = "LAMPKey"
  public_key = file(var.PATH_PUBLIC_KEY)
}

resource "aws_vpc" "LAMP-VPC" {
    cidr_block = var.VPC_IP_POOL
    instance_tenancy = "default"
    
    tags = {
      "Name" = "LAMP-VPC"
    }
}

resource "aws_subnet" "LAMP-public" {
    vpc_id = aws_vpc.LAMP-VPC.id
    cidr_block = var.public_subnet_pool

    tags = {
      "Name" = "LAMP-public"
    }
  
}

resource "aws_internet_gateway" "LAMP-IG" {
    vpc_id = aws_vpc.LAMP-VPC.id

    tags = {
      "Name" = "LAMP-IG"
    }
  
}

resource "aws_route_table" "public-route-table" {
    depends_on = [aws_internet_gateway.LAMP-IG]
    vpc_id = aws_vpc.LAMP-VPC.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.LAMP-IG.id
    }

    route {
        ipv6_cidr_block        = "::/0"
        gateway_id = aws_internet_gateway.LAMP-IG.id
    }

    tags = {
      "Name" = "Public-RouteTable"
    }
  
}

resource "aws_route_table_association" "public-route-table-attach" {
    subnet_id = aws_subnet.LAMP-public.id
    route_table_id = aws_route_table.public-route-table.id
  
}

resource "aws_security_group" "LAMPsg" {
  name        = "LAMPsg"
  description = "Allow ssh  inbound traffic"
  vpc_id = aws_vpc.LAMP-VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]

  }
}

resource "aws_instance" "app_server" {
  ami           = lookup(var.AMIS, var.AWS_REGION, "")
  instance_type = "t2.micro"
  key_name = aws_key_pair.LAMPkey.key_name
  vpc_security_group_ids = [aws_security_group.LAMPsg.id]
  subnet_id = aws_subnet.LAMP-public.id
  associate_public_ip_address = true
  provisioner "file" {
    source      = "LAMP.sh"
    destination = "/tmp/LAMP.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/LAMP.sh",
      "sudo sed -i -e 's/\r$//' /tmp/LAMP.sh",  # Remove the spurious CR characters.
      "sudo /tmp/LAMP.sh '${var.MYSQL_Password}'",
    ]
    
  }
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.INSTANCE_USERNAME
    private_key = file(var.PATH_PRIVATE_KEY)
  }

  tags = {
    Name = "LAMP Server"
  }
}

resource "aws_eip" "LAMP-EIP" {
  vpc = true

  instance                  = aws_instance.app_server.id
  associate_with_private_ip = aws_instance.app_server.private_ip
  depends_on                = [aws_internet_gateway.LAMP-IG]

  tags = {
    Name = "LAMP-EIP"
  }
}