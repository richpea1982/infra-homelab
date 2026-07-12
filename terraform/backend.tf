terraform {
  backend "s3" {
    bucket   = "homelab-tf-state"
    key      = "homelab/terraform.tfstate"
    region = "main"
    endpoints = {
      s3 = "http://10.0.10.17:9000"   # MinIO on the NAS
    }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}
