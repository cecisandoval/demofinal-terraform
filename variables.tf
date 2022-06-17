
variable "profile"{
    type = string
    default = "default"

}

variable "region-master" {
    type = string
    default = "us-west-2"
}

variable "ami-master" {
    type = string
    default = "ami-0bfb52e87a0ca5788"
}


variable "ami-msql" {
    type = string
    default = "ami-0bfb52e87a0ca5788"
}


variable "instance-type" {
    type = string
    default = "t2.micro"
}


#ami-0ee8244746ec5d6d4
#ami-0ee8244746ec5d6d4