provider "aws" {
    region = "eu-west-1"
}

resource "aws_instance" "terraform-example" {
  ami             = "ami-405f7226"
  instance_type   = "t2.micro"

  tags {
    Name = "terraform-example"
  }
}
