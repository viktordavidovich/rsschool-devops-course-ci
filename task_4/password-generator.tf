resource "random_password" "k3s_token" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "_%@"
}