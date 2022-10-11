resource "aws_codebuild_project" "cicd-plan" {
  name         = "cicd-plan"
  description  = "Plan stage for terraform"
  service_role = aws_iam_role.cicd-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.2.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    #registry_credential {
      #credential          = var.dockerhub_credentials
     # credential_provider = "SECRETS_MANAGER"
    #}
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/planspec.yaml")
  }
}

resource "aws_codebuild_project" "cicd-apply" {
  name         = "cicd-apply"
  description  = "Apply stage for terraform"
  service_role = aws_iam_role.cicd-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:0.14.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    #registry_credential {
     # credential          = var.dockerhub_credentials
      #credential_provider = "SECRETS_MANAGER"
    #}
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/applyspec.yaml")
  }
}


resource "aws_codepipeline" "cicd_pipeline" {

  name     = "tf-cicd"
  role_arn = aws_iam_role.cicd-cp-role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.gkrcicd_artifacts.id
  }
  #coonnect github and pass the source code
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["tf-code"]
      configuration = {
        FullRepositoryId     = "gkrrepo/cicd-tf"
        BranchName           = "master"
        ConnectionArn        = var.codestar_connector_credentials
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "cicd-plan"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "cicd-apply"
      }
    }
  }

}

resource "aws_s3_bucket" "gkrcicd_artifacts" {
  bucket = "gkrcicd-artifacts"
}

resource "aws_s3_bucket_acl" "gkrcicd_acl" {
  bucket = aws_s3_bucket.gkrcicd_artifacts.id
  acl    = "private"
}
