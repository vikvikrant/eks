

resource "aws_iam_role" "ebs_csi_role" { 
  name               = "aws-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_this_assume.json
  
}


data "aws_iam_policy_document" "ebs_csi_this_assume" {
  statement {
    effect = "Allow"
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    principals {
      type        = "Federated"
      identifiers = [ aws_iam_openid_connect_provider.example.arn ] 
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.example.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:ebs-csi-controller-sa",
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


resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
  role = aws_iam_role.ebs_csi_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


# resource "kubernetes_service_account" "ebs_csi_sa" {
#   metadata {
#     name = "ebs-csi-controller-sa"
#     namespace =  "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn": aws_iam_role.ebs_csi_role.arn
#     }
#   }
# }

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.26.0-eksbuild.1"
  service_account_role_arn    = aws_iam_role.ebs_csi_role.arn
}