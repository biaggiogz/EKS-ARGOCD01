SHELL := /bin/bash

deploy: init eks


apply: eks

init:
	terraform init

eks:
	terraform apply -target="module.eks" -auto-approve
	terraform output -raw configure_kubectl | bash

destroy: delete-eks-cluster

delete-eks-cluster:
	terraform destroy -target="module.eks" -auto-approve

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'
.PHONY: *