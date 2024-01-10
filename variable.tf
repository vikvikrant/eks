variable "subnet_ids" {
    type = list
    default = ["subnet-072b062ae0f500689","subnet-0eab3d097c96dd730"]
}

variable "vpc_id" {
    type = string
    default = "vpc-0cadc1183a8ac658a"
}

variable "cluster_name" {
  type        = string
  default     = "eks_cluster"
  description = "eks cluster"
}

variable "cluster_role_name" {
  type        = string
  default     = "eks_cluster_role"
  description = "eks cluster role"
}
