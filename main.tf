# Configure the AWS Provider
provider "aws"  {
  region = "us-east-1"
}
# create the 4 EA ec2 instances
resource "aws_instance" "app_server" {
  count         = 4
  ami           = "ami-0aedf6b1cb669b4c7"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name

  tags = {
    Name = "Test-Multi-Instance#${count.index + 1}"
    Env  = "dev"
  }
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "utc-app1"
  cidr = "192.168.0.0/16"
}
# Generate a secure key using a rsa algorithm
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# creating the keypair in aws
resource "aws_key_pair" "ec2_key" {
  key_name   = "my-ec2-keypair"                 
  public_key = tls_private_key.ec2_key.public_key_openssh 
}

# Save the .pem file locally for remote connection
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.ec2_key.key_name}.pem"
  content  = tls_private_key.ec2_key.private_key_pem
}

# create the security group to allow the ssh remote connection
# here the instance will be created in the default VPC

resource "aws_security_group" "sg" {
  name        = "my-security-group"
  description = "allow traffic on 22 and 80"
  vpc_id      = module.vpc.vpc_id
  

  ingress {
    description      = "22 for ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
   ingress {
    description      = "80 for http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
}

# print the ssh remote connection command
output "ssh_command" {
  value = "ssh -i my-ec2-keypair.pem centos@$${aws_instance.app_server count.index}"
}