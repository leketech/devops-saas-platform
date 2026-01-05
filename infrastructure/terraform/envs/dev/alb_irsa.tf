data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:sub"
      # service account used by AWS Load Balancer Controller in kube-system
      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "dev-eks-alb-controller-irsa"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_policy" "alb_policy" {
  name        = "dev-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller (from repo)"
  policy      = file("../../../aws/iam/alb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_policy.arn
}

output "alb_irsa_role_arn" {
  value = aws_iam_role.alb_controller.arn
}
