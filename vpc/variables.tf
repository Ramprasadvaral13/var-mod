variable "vpc-cidr" {
    type = string
  
}

variable "route-cidr" {
    type = string
  
}

variable "subnet" {
    type = map(object({
      cidr = string
      az = string
      ip = bool
    }))
}