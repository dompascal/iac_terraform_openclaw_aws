variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = true
}

variable "openclaw_config" {
  description = "OpenClaw configuration settings (JSON string)"
  type        = string
  default     = "{}"
}

variable "use_elastic_ip" {
  description = "Whether to allocate an Elastic IP"
  type        = bool
  default     = false
}

variable "openclaw_gateway_token" {
  description = "OpenClaw gateway authentication token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "moonshot_api_key" {
  description = "Kimi/Moonshot API key from platform.moonshot.cn"
  type        = string
  sensitive   = true
}

variable "moonshot_model" {
  description = "Moonshot model to use (moonshot-v1-8k, moonshot-v1-32k, moonshot-v1-128k)"
  type        = string
  default     = "moonshot-v1-8k"
}
