SHELL := /bin/bash


deploy: init \
 karpenter

init:
	terraform init

karpenter:
	terraform apply -target="kubernetes_namespace.karpenter" -auto-approve
	terraform apply -target="module.karpenter" -auto-approve
	terraform apply -target="aws_eks_pod_identity_association.karpenter" -auto-approve
	terraform apply -target="null_resource.mapping_karpenter" -auto-approve
	terraform apply -target="helm_release.karpenter" -auto-approve
	chmod 777 patch_cdrs_karpenter.sh && ./patch_cdrs_karpenter.sh

destroykarpenter:
	terraform destroy -target="helm_release.karpenter" -auto-approve
	terraform destroy -target="null_resource.delete_mapping_karpenter" -auto-approve
	terraform destroy -target="aws_eks_pod_identity_association.karpenter" -auto-approve
	terraform destroy -target="module.karpenter" -auto-approve
	terraform destroy -target="kubernetes_namespace.karpenter" -auto-approve


prometheus:
	terraform init
	terraform apply -target="module.prometheus" -auto-approve



.PHONY: *