provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "webapp" {
  backend = "s3"
  config {
    bucket = "lab00-tfstate"
    key    = "prod/terraform-prod.tfstate"
    region = "eu-west-1"
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "temp" {
  template = "${file("userdata.tpl")}"

  vars {
    username = "ubuntu"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${data.terraform_remote_state.webapp.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count = 2
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "FBlab"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  user_data = "${data.template_file.temp.rendered}"
  subnet_id = "${element(data.terraform_remote_state.webapp.subnet1_id, count.index)}"


  tags {
    Name = "HelloWorld"
  }
}

