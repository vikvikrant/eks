
# resource "aws_iam_role_policy" "autoscaler_policy" {
#   name = "autosclaer"
#   role = aws_iam_role.autoscaler_role.id
#   policy = file("${path.module}/iam-policy-autoscaler.json")
# }


# resource "aws_iam_role" "autoscaler_role" { 
#   name               = "cluster-autoscaler-role"
#   assume_role_policy = data.aws_iam_policy_document.autoscaler.json
  
# }


# data "aws_iam_policy_document" "autoscaler" {
#   statement {
#     effect = "Allow"
    
#     actions = ["sts:AssumeRoleWithWebIdentity"]
    
#     principals {
#       type        = "Federated"
#       identifiers = [ aws_iam_openid_connect_provider.example.arn ]  #[var.cluster_identity_oidc_issuer_arn]
#     }
# }
# }



# resource "helm_release" "autoscaler" {
#   name       = "autoscaler"
#   repository = "https://kubernetes.github.io/autoscaler"
#   chart      = "cluster-autoscaler"
#   namespace  = "kube-system"
#   # depends_on = [
#   #   kubernetes_service_account.aws_lbc
#   # ]

#   set {
#     name  = "awsRegion"
#     value = "eu-east-2"
#   }

#   set {
#     name  = "autoDiscovery.clusterName"
#     value = var.cluster_name
#   }

#   set {
#     name  = "autoDiscovery.roles"
#     value = "aws_iam_role.autoscaler_role.arn"
#   }
  
# }