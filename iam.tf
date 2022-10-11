#role for pipeline
resource "aws_iam_role" "cicd-cp-role" {
  name = "cicd-cp-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "cicd-pipeline-policies" {
  statement {
    sid       = ""
    actions   = ["codestar-connections:UseConnection"]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    sid       = ""
    actions   = ["cloudwatch:*", "s3:*", "codebuild:*"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "cicd-pipeline-policy" {
  name        = "cicd-pipeline-policy"
  path        = "/"
  description = "Pipeline policy"
  policy      = data.aws_iam_policy_document.cicd-pipeline-policies.json
}

resource "aws_iam_role_policy_attachment" "cicd-pipeline-attachment" {
  policy_arn = aws_iam_policy.cicd-pipeline-policy.arn
  role       = aws_iam_role.cicd-cp-role.id
}


#role for codebuild
resource "aws_iam_role" "cicd-codebuild-role" {
  name = "cicd-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "cicd-build-policies" {
  statement {
    sid       = ""
    actions   = ["logs:*", "s3:*", "codebuild:*", "secretsmanager:*", "iam:*"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "cicd-build-policy" {
  name        = "cicd-build-policy"
  path        = "/"
  description = "Codebuild policy"
  policy      = data.aws_iam_policy_document.cicd-build-policies.json
}

resource "aws_iam_role_policy_attachment" "cicd-codebuild-attachment1" {
  policy_arn = aws_iam_policy.cicd-build-policy.arn
  role       = aws_iam_role.cicd-codebuild-role.id
}

resource "aws_iam_role_policy_attachment" "cicd-codebuild-attachment2" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.cicd-codebuild-role.id
}
