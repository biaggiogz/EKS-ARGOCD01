SHELL := /bin/bash

deploykarpenter:
	terraform init
	terraform apply -target="module.karpenter" -auto-approve
	chmod 770 /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/patch_cdrs_karpenter.sh
	sh /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/patch_cdrs_karpenter.sh
	kubectl apply -f /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/karpenter/general.yaml

applykarpenter:
	terraform init
	terraform apply -target="module.karpenter" -auto-approve

destroykarpenter:
	terraform destroy -target="module.karpenter" -auto-approve

deployaddons:
	terraform init
	terraform apply -target="module.addons" -auto-approve

destroyaddons:
	terraform destroy -target="module.addons" -auto-approve

deployprometheus:
	terraform init
	terraform apply -target="module.prometheus" -auto-approve

destroyprometheus:
	terraform destroy -target="module.prometheus" -auto-approve

deploykubecost:
	terraform init
	terraform apply -target="module.kubecost" -auto-approve

destroykubecost:
	terraform destroy -target="module.kubecost" -auto-approve

.PHONY: *
