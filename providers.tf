provider "aws" {
    profile = var.profile
    region = var.region-master
    alias = "region-master"
    

}

provider "fakewebservices" {
  token = var.provider_token
}

