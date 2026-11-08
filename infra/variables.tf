variable "project" {
  description = "Prefijo de todos los nombres"
  type        = string
  default     = "andes"
}

variable "environment" {
  description = "Entorno: dev, qa, prod"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus2"
}

variable "owner" {
  description = "Responsable, va en el tag owner"
  type        = string
}

variable "alert_email" {
  description = "Correo que recibe las alertas"
  type        = string
}

variable "vm_size" {
  description = "Tamaño de la VM"
  type        = string
  default     = "Standard_B1s"
}
