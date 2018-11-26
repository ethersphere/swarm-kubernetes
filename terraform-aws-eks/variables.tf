variable "cluster-name" {
  default = "your-cluster-name"
  type    = "string"
}

variable "cluster-region" {
  default = "us-east-1"
  type    = "string"
}

variable "cluster-swarm-instance-type" {
  default = "m4.xlarge"
  type    = "string"
}

variable "cluster-swarm-spot-bid-price" {
  default = "0.10"
  type    = "string"
}

variable "cluster-swarm-desired-capacity" {
  default = "5"
  type    = "string"
}

variable "cluster-geth-instance-type" {
  default = "i3.large"
  type    = "string"
}

variable "cluster-geth-spot-bid-price" {
  default = "0.20"
  type    = "string"
}

variable "cluster-geth-desired-capacity" {
  default = "2"
  type    = "string"
}

variable "cluster-key-name" {
  default = "your-ssh-key"
  type    = "string"
}
