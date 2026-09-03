terraform {
  backend "s3" {
    bucket         = "taskapp-tfstate-270293010266-us-east-1"
    key            = "dev/cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "taskapp-terraform-locks"
    encrypt        = true
  }
}