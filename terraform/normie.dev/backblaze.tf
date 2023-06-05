provider "b2" {
  application_key    = data.sops_file.backblaze-secrets.data["application_key"]
  application_key_id = data.sops_file.backblaze-secrets.data["application_key_id"]
}

locals {
  default_capabilities = toset([
    "listBuckets",
    "listAllBucketNames",
    "readBuckets",
    "readBucketRetentions",
    "writeBucketRetentions",
    "listFiles",
    "readFiles",
    "writeFiles",
    "deleteFiles",
    "readFileRetentions",
    "writeFileRetentions"
  ])
}

resource "b2_bucket" "keanu-emails" {
  bucket_name = "normie-dev-keanu-emails"
  bucket_type = "allPrivate"

  cors_rules {
    cors_rule_name  = "keanu-email"
    max_age_seconds = 600

    allowed_operations = [
      "b2_download_file_by_name",
      "b2_download_file_by_id",
      "b2_upload_file",
      "b2_upload_part",
      "s3_delete",
      "s3_get",
      "s3_head",
      "s3_post",
      "s3_put"
    ]
    allowed_origins = [
      "https://${cloudflare_zone.normie_dev.zone}",
      "https://www.${cloudflare_zone.normie_dev.zone}",
      "https://mx.${cloudflare_zone.normie_dev.zone}"
    ]
  }

  lifecycle_rules {
    file_name_prefix              = ""
    days_from_hiding_to_deleting  = 30
    days_from_uploading_to_hiding = null
  }
}

resource "b2_application_key" "keanu-emails" {
  key_name  = "keanu-emails-bucket"
  bucket_id = b2_bucket.keanu-emails.bucket_id

  capabilities = local.default_capabilities
}
