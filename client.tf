# creates an application instance (EC2)

data "aws_ami" "ec2_ami" {
  most_recent             = true
  owners                  = ["amazon"]

  filter {  
    name                  = "name"
    values                = ["amzn2-ami-hvm-2*"]
  } 

  filter {  
    name                  = "architecture"
    values                = ["x86_64"]
  } 

  filter {  
    name                  = "root-device-type"
    values                = ["ebs"]
  } 

  filter {  
    name                  = "virtualization-type"
    values                = ["hvm"]
  } 
}

resource "aws_instance" "client_app" {
  ami                     = data.aws_ami.ec2_ami.id

  subnet_id               = data.aws_subnet.client[0].id
  vpc_security_group_ids  = [ aws_security_group.client_sg.id ]

  instance_type           = "t3.small"
  credit_specification {
    cpu_credits           = "standard"
  }
  key_name                = var.client_ssh_keypair_name
  iam_instance_profile    = aws_iam_instance_profile.ec2_instance_profile.name

  user_data               = <<EOF
#!/bin/bash -xe

amazon-linux-extras install -y postgresql13

EOF

  tags                    = merge(local.common_tags, tomap({"Name": "${var.app_shortcode}-client-app"}))
}
