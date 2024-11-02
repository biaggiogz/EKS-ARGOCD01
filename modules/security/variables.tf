# modules/security/variables.tf

variable "namespaces" {
  type    = list(string)
  default = ["integration", "development"]
}

variable "roles" {
  type = map(object({
    namespace = string
    name      = string
  }))
  default = {
    dev = {
      namespace = "development"
      name      = "dev-role"
    }
    integ = {
      namespace = "integration"
      name      = "integ-role"
    }
  }
}