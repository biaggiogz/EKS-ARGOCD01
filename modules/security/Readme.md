# Folder Security Explanation

## roles.tf
To create an iam roles , users and groups for kubernetes with their policies

## kubernetes-rbac.tf
Configure Kubernetes RBAC Roles
- development namespace will be accessible for IAM users from k8sDev group
- integration namespace will be accessible for IAM users from k8sInteg group

## kubernetes-config-map.tf
We will just need to add or remove users from the IAM Group, and we just configure the ConfigMap to allow the IAM Role associated to the IAM Group
- A RBAC role for K8sAdmin, mapped to give access to system:masters kubernetes Groups so that it has Full Admin rights on the cluster
- A RBAC role for k8sDev that we map on dev-user in development Namespace
- A RBAC role for k8sInteg that we map on integ-user in integration Namespace