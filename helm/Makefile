SHELL := /bin/bash


deploy: init \
 nkarpenter

init:
	terraform init

karpenter:
	terraform apply -target="kubernetes_namespace.karpenter" -auto-approve
	terraform apply -target="module.karpenter" -auto-approve
	terraform apply -target="aws_eks_pod_identity_association.karpenter" -auto-approve
	terraform apply -target="helm_release.karpenter" -auto-approve
	terraform apply -target="helm_release.karpenter" -auto-approve
    chmod 777 patch_cdrs_karpenter.sh
    ./patch_cdrs_karpenter.sh
.PHONY: *