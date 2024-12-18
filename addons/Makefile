SHELL := /bin/bash


deploy: init \
 ebs-addons

init:
	terraform init

ebs-addons:
	terraform apply -target="aws_iam_role.ebs_csi_driver" -auto-approve
	terraform apply -target="aws_iam_role_policy_attachment.ebs_csi_driver_policy" -auto-approve
	terraform apply -target="kubernetes_service_account.ebs_csi_controller_sa" -auto-approve
	terraform apply -target="aws_eks_pod_identity_association.ebs_csi_driver" -auto-approve
	terraform apply -target="aws_eks_addon.ebs_csi_driver" -auto-approve

.PHONY: *