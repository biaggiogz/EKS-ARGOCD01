.PHONY: destroy

export TF_VAR_password_grafana := Asimo1721.
export TF_VAR_deploy_number := 03

destroy:
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ destroykubecosts
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ destroyprometheus
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/03_helm/ destroyaddons
	$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/02_eks/ destroyeks
	#$(MAKE) -C /home/aniking/Documents/IdeaProjects/EKS-03/01_vpc/ destroyvpc

