SHELL := /bin/bash

deploykarpenter:
	terraform init
	terraform apply -target="module.karpenter" -auto-approve
    chmod 770 /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/patch_cdrs_karpenter.sh
    sh /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/patch_cdrs_karpenter.sh
    kubectl apply -f /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/karpenter/general.yaml

destroykarpenter:
	terraform destroy -target="module.karpenter" -auto-approve



prometheus:
	terraform init
	terraform apply -target="module.prometheus" -auto-approve



.PHONY: *