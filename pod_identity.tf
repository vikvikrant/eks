data "aws_iam_policy_document" "assume_role_pod_identity" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "pod-identity" {
  name               = "eks-pod-identity-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pod_identity.json
}

resource "aws_iam_role_policy_attachment" "example_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.pod-identity.name
}

resource "aws_eks_pod_identity_association" "example" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  namespace       = "mac"
  service_account = "new-sa"
  role_arn        = aws_iam_role.pod-identity.arn
}