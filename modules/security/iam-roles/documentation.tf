resource "local_file" "role_documentation" {
  filename = "${path.module}/roles_documentation.md"
  content  = <<-EOT
# IAM Roles

%{for name, description in local.roles~}
## ${name}
${description}

%{endfor~}
  EOT
}