##############################################################################
# Variables
##############################################################################

variable "list" {
  description = "List of strings"
  type        = list(string)
}

variable "add" {
  description = "String to add to list"
  type        = string
}

variable "if_true" {
  description = "Value that if true will force list to concat with value"
}

##############################################################################

##############################################################################
# Outputs
##############################################################################

output "list" {
  description = "List concat if true"
  value = concat(
    var.list,
    var.if_true == true ? [var.add] : []
  )
}

##############################################################################