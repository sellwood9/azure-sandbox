variable "location" {
  description = "Azure region for basecamp resources."
  type        = string
  default     = "eastus2"
}

variable "budget_amount" {
  description = "Monthly subscription budget in the billing currency."
  type        = number
  default     = 100
}

variable "budget_contact_emails" {
  description = "Addresses that receive budget alerts."
  type        = list(string)

  validation {
    condition     = length(var.budget_contact_emails) > 0
    error_message = "At least one budget contact email is required."
  }
}

variable "expires" {
  description = "Value for the expires tag (yyyy-mm-dd). Basecamp is long-lived."
  type        = string
  default     = "2027-10-21"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expires))
    error_message = "expires must be yyyy-mm-dd."
  }
}

variable "subscription_id" {
  description = "Personal sandbox subscription. Pinned to prevent deploying to a work subscription."
  type        = string
}

variable "tenant_id" {
  description = "Personal tenant."
  type        = string
}
