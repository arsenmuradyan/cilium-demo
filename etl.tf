resource "aws_s3_bucket" "http_logs" {
  bucket        = "http-logs-bucket-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}
resource "aws_iam_role" "vector_kinesis_writer" {
  name               = "vector-kinesis-writer"
  assume_role_policy = data.aws_iam_policy_document.vector_irsa_assume_role.json
}
data "aws_iam_policy_document" "vector_irsa_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

  }
}
resource "aws_iam_policy" "vector_kinesis_put_policy" {
  name = "vector-kinesis-put-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "kinesis:*",
      ],
      Effect   = "Allow",
      Resource = aws_kinesis_stream.http_logs_stream.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vector_kinesis_attach" {
  role       = aws_iam_role.vector_kinesis_writer.name
  policy_arn = aws_iam_policy.vector_kinesis_put_policy.arn
}
resource "aws_iam_role" "firehose_role" {
  name = "firehose_delivery_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "firehose.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_s3_access"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation"
        ],
        Resource = "${aws_s3_bucket.http_logs.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ],
        Resource = aws_kinesis_stream.http_logs_stream.arn
      },
      {
        Effect   = "Allow",
        Action   = "logs:*",
        Resource = "*"
      }
    ]
  })
}
resource "aws_kinesis_stream" "http_logs_stream" {
  name             = "http-logs-stream"
  shard_count      = 1
  retention_period = 24
}
resource "aws_kinesis_firehose_delivery_stream" "http_logs_stream" {
  name        = "http-traffic-stream"
  destination = "extended_s3"
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.http_logs_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }
  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.http_logs.arn
    prefix             = "logs/"
    buffering_size     = 5
    buffering_interval = 300
    compression_format = "GZIP"

    processing_configuration {
      enabled = "true"
      processors {
        type = "AppendDelimiterToRecord"
      }
    }
  }
}


resource "aws_glue_catalog_database" "http_logs_db" {
  name = "http_logs_db"
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "glue_crawler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "glue_crawler_policy" {
  name = "glue_crawler_policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.http_logs.arn,
          "${aws_s3_bucket.http_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "glue:*"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_glue_crawler" "http_log_crawler" {
  name          = "http-log-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.http_logs_db.name
  table_prefix  = "http_"

  s3_target {
    path = "s3://${aws_s3_bucket.http_logs.bucket}/logs"
  }

  schedule = "cron(0/30 * * * ? *)" # every 30 minutes



  depends_on = [aws_kinesis_firehose_delivery_stream.http_logs_stream]
}
