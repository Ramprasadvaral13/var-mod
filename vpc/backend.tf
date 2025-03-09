terraform {
  backend "s3" {
    bucket = "my-vpc-bucket-tf-dev"
    key = "vpc/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-lock-table-dev"
    
  }
}