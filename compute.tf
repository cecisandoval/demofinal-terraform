
#resource "aws_key_pair" "instance_key" {
  #key_name   = "e"
  #public_key = "${file("c.pem")}"
#}



#Create key-pair for  EC2 
resource "aws_key_pair" "instance_key" {
  provider = aws.region-master
  key_name = "instance_key"
  public_key = file("~/.ssh/id_rsa.pub")
}



#create EC2 instance 
resource "aws_instance" "web_server1" {
    provider = aws.region-master
    ami = "ami-0ee8244746ec5d6d4"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.sgw.id]
    subnet_id = aws_subnet.sub_private1.id
    key_name = aws_key_pair.instance_key.key_name
    #user_data = "${file("install_apache.sh")}"

    provisioner "remote-exec" {
        inline = [
            "sudo apt-get -y update",
            "sudo apt-get -y install nginx"
            #"sudo systemctl start apache2"
            #"sudo bash -c 'echo '<h1> Task 2 - Hello World from - Task 8 $(hostname -f)</h1>' > /var/www/html/index.html'"
        ]
        connection {
        type = "ssh"
	    user = "ubuntu"
        private_key = file("~/.ssh/id_rsa")
	    host = self.public_ip
        }


    }
    tags = {
	Name = "web_server1"	
	Batch = "5AM"
    }
}


#create Application LoadBalancer
resource "aws_lb" "application_lb" {
    provider = aws.region-master
    name = "ALB-task8"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.sglb.id]
    subnets  = [aws_subnet.sub_public1.id,aws_subnet.sub_public2.id]
    tags = {
        Name = "ALB-task8"
    }
}

resource "aws_lb_target_group" "tg-lb-task8" {
    provider = aws.region-master
    name = "TG-lb-task8"
    port = 80
    target_type = "instance"
    vpc_id = aws_vpc.vpc.id
    protocol = "HTTP"
    health_check {
        enabled = true
        interval = 10
        path = "/"
        port = 80
        protocol = "HTTP"
        matcher = "200-299"
    }

}

resource "aws_lb_listener" "listener-http" {
    provider = aws.region-master
    load_balancer_arn = aws_lb.application_lb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg-lb-task8.arn
    }
}

resource "aws_lb_target_group_attachment" "attache_instance" {
    provider = aws.region-master
    target_group_arn = aws_lb_target_group.tg-lb-task8.arn
    target_id = aws_instance.web_server1.id
    port = 80

}







