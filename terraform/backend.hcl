bucket                      = "tf-state"
region                      = "us-east-1"
endpoints                   = { s3 = "http://10.30.5.20:7480" }
use_path_style              = true
use_lockfile                = true
skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
skip_s3_checksum            = true
