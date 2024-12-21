SHELL := /bin/bash


deployeks:
	terraform init
	terraform apply -auto-approve
	terraform output -raw configure_kubectl | bash
	eks_status=$$(terraform output -raw eks_cluster_status); \
	echo "export EKS_STATUS=$$eks_status" >> ~/.bashrc; \
	source ~/.bashrc; \
	echo "EKS Cluster Status: $$eks_status"

applyeks:
	terraform apply -auto-approve
	terraform output -raw configure_kubectl | bash
	export eks_status=$(terraform output -raw eks_cluster_status)

destroyeks:
	terraform destroy -auto-approve

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'
.PHONY: *