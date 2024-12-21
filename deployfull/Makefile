.PHONY: deploy check_status deploy_rest

export TF_VAR_password_grafana := Asimo1721.
export TF_VAR_deploy_number := 03

deploy:
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/01_vpc/ deployvpc
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/02_eks/ deployeks
	$(MAKE) check_status

check_status:
	@EKS_STATUS=$$(aws eks describe-cluster --name eks-03 --query 'cluster.status' --output text); \
	if [ "$$EKS_STATUS" = "ACTIVE" ]; then \
		echo "EKS Cluster Status: $$EKS_STATUS"; \
		$(MAKE) deploy_karpenter_and_addons; \
	else \
		echo "EKS Cluster is not active. Current status: $$EKS_STATUS"; \
		exit 1; \
	fi

deploy_rest:
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ deploykarpenter
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ deployaddons
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ deployaddons
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ deployprometheus
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ deploykubecosts
