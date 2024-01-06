data "tls_certificate" "example" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "example" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.example.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.example.url
}




resource "aws_iam_role_policy" "irsa_policy" {
  name = "AWSLoadBalancerControllerIAMPolicy"
  role = aws_iam_role.irsa_role.id
  policy = file("${path.module}/iam-policy.json")
}

resource "aws_iam_role" "irsa_role" { 
  name               = "aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.this_assume.json
  
}


data "aws_iam_policy_document" "this_assume" {
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
        "system:serviceaccount:kube-system:aws-load-balancer-controller",
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


resource "kubernetes_service_account" "aws_lbc" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace =  "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn": aws_iam_role.irsa_role.arn
    }
  }
}
