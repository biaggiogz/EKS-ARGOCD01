SHELL := /bin/bash


deploy: init \
 eks



init:
	terraform init

eks:
	terraform apply -target="module.eks" -auto-approve
	terraform output -raw configure_kubectl | bash
##########################################################################
apply: eks

###########################################################################
destroy: delete-eks-cluster


delete-eks-cluster:
	terraform destroy -target="module.eks" -auto-approve


.PHONY: *