resource "aws_s3_bucket" "prod_media" {
  bucket = var.prod_media_bucket
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.prod_media.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.prod_media.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.prod_media]
}

resource "aws_s3_bucket_public_access_block" "prod_media" {
  bucket = aws_s3_bucket.prod_media.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "prod_media_bucket_cors" {
  bucket = aws_s3_bucket.prod_media.bucket
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "prod_media_bucket_policy" {
  bucket = aws_s3_bucket.prod_media.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = [
          "arn:aws:s3:::${var.prod_media_bucket}",
          "arn:aws:s3:::${var.prod_media_bucket}/*"
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.prod_media]
}

resource "aws_iam_user" "prod_media_bucket" {
  name = "prod-media-bucket"
}

resource "aws_iam_user_policy" "prod_media_bucket" {
  user = aws_iam_user.prod_media_bucket.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.prod_media.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.prod_media.bucket}/*"
        ],
      },
    ],
  })
}

resource "aws_iam_access_key" "prod_media_bucket" {
  user = aws_iam_user.prod_media_bucket.name
}
