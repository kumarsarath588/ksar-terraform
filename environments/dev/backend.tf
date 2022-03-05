terraform {
    backend "s3" {
        bucket         = "ksar-terraform-state"
        key            = "dev/terraform.tfstate"
        region         = "us-west-1"
    }
}