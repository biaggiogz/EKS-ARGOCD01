SHELL := /bin/bash


deployeks:
	terraform init
	terraform apply -auto-approve
	terraform output -raw configure_kubectl | bash

applyeks:
	terraform apply -auto-approve
	terraform output -raw configure_kubectl | bash

destroyeks:
	terraform destroy -target="module.eks" -auto-approve

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'
.PHONY: *