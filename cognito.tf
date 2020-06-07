resource "aws_cognito_user_pool" "default" {
  name = "mediacodex"

  //from = "noreply@${var.domain}"
  // TODO: mfa_configuration = "OPTIONAL"

  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  /*email_configuration {
    email_sending_account = "DEVELOPER"
    source_arn            = aws_ses_domain_identity.default.arn
  }*/

  // https://docs.microsoft.com/en-us/office365/admin/misc/password-policy-recommendations
  // https://pages.nist.gov/800-63-3/sp800-63b.html
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  tags = var.default_tags
}
