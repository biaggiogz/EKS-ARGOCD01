
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = "karpenter-interruption-queue${local.cluster_name}"
  message_retention_seconds = 43200
  sqs_managed_sse_enabled   = true
  tags = {
    Environment = "production-01"
    Purpose     = "Karpenter"
  }

}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKarpenterToReceiveMessages"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "karpenter_sqs_policy" {
  name = "karpenter-sqs-policy"
  role = aws_iam_role.karpenter_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}