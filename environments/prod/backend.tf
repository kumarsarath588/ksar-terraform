terraform {
    backend "s3" {
        bucket         = "ksar-terraform-state"
        key            = "prod/terraform.tfstate"
        region         = "us-west-1"
    }
}