variable "server_port" {
  description = "HTTP port"
  default = 8080
}

/*output "public_ip" {
  value = "${aws_instance.terraform-example.public_ip}"
}*/

output "elb_dns_name" {
  value = "${aws_elb.terraform-elb.dns_name}"
}

provider "aws" {
    region = "eu-west-1"
}


resource "aws_launch_configuration" "terraform-example" {
  image_id        = "ami-405f7226"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Test" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  /*tags {
    Name = "terraform-example"
  }*/

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "terraform-elb" {
  name = "terraform-example-elb"

  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance" {
  description = "Security Group for my awesome web app"
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "terraform-example" {
  launch_configuration  = "${aws_launch_configuration.terraform-example.id}"
  availability_zones        = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.terraform-elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 6

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "terraform-elb" {
  name                = "terraform-asg-LB"
  availability_zones  = ["${data.aws_availability_zones.all.names}"]
  security_groups     = ["${aws_security_group.terraform-elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 60
    target              = "HTTP:${var.server_port}/"
  }
}
