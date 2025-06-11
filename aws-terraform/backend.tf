terraform {
  # Use S3 remote state and locking
  backend "s3" {
    encrypt      = true
    kms_key_id   = "alias/aws/s3"
    use_lockfile = true
  }
}
