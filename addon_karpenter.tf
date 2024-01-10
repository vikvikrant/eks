resource "aws_iam_role_policy" "karpenter_contoller" {
  name = "karpenter-policy"
  role = aws_iam_role.karpenter_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "karpenter_role" { 
  name               = "karpenter-role"
  assume_role_policy = data.aws_iam_policy_document.karpenter.json
  
}


data "aws_iam_policy_document" "karpenter" {
  statement {
    effect = "Allow"
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    principals {
      type        = "Federated"
      identifiers = [ aws_iam_openid_connect_provider.example.arn ]  #[var.cluster_identity_oidc_issuer_arn]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.example.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:karpenter:karpenter",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.tls_certificate.example.url, "https://", "")}:aud"

      values = [
        "sts.amazonaws.com",
      ]
    }
  }
}


resource "kubernetes_service_account" "karpenter" {
  metadata {
    name = "karpenter"
    namespace =  "karpenter"
    annotations = {
      "eks.amazonaws.com/role-arn": aws_iam_role.karpenter_role.arn
    }
  }
}




resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  version    = "0.16.3"
  chart      = "karpenter"
  namespace  = "karpenter"
  depends_on = [
    kubernetes_service_account.karpenter
  ]


  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = aws_eks_cluster.eks_cluster.endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_role.arn
  }
  
}


# ######
# data "aws_iam_policy_document" "assume_role_pod_identity" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }

#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }

# resource "aws_iam_role" "pod-identity" {
#   name               = "eks-pod-identity-example"
#   assume_role_policy = data.aws_iam_policy_document.assume_role_pod_identity.json
# }

# resource "aws_iam_role_policy_attachment" "example_s3" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
#   role       = aws_iam_role.pod-identity.name
# }

# resource "aws_eks_pod_identity_association" "example" {
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   namespace       = "mac"
#   service_account = "new-sa"
#   role_arn        = aws_iam_role.pod-identity.arn
# }