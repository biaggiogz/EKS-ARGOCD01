#############################################STEP 1###############################


#export KARPENTER_NAMESPACE="karpenter"
#export KARPENTER_VERSION="1.0.8"  ##############version stable
#export K8S_VERSION="1.30"


#export AWS_PARTITION="aws" # if you are not using standard partitions, you may need to configure to aws-cn / aws-us-gov
#export CLUSTER_NAME="EKS-02"
#export AWS_DEFAULT_REGION="eu-north-1"
#export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
#export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
#export TEMPOUT="$(mktemp)"
#export ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
#export AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
#export GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"
#echo "${KARPENTER_NAMESPACE}" "${KARPENTER_VERSION}" "${K8S_VERSION}" "${CLUSTER_NAME}" "${AWS_DEFAULT_REGION}" "${AWS_ACCOUNT_ID}" "${TEMPOUT}" "${ARM_AMI_ID}" "${AMD_AMI_ID}" "${GPU_AMI_ID}"
#curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/v"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
#&& aws cloudformation deploy \
#--stack-name "Karpenter-${CLUSTER_NAME}" \
#--template-file "${TEMPOUT}" \
#--capabilities CAPABILITY_NAMED_IAM \
#--parameter-overrides "ClusterName=${CLUSTER_NAME}"

#############################################STEP 2###############################


#eksctl create iamidentitymapping \
#  --username system:node:{{EC2PrivateDNSName}} \
#  --cluster "${CLUSTER_NAME}" \
#  --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
#  --group system:bootstrappers \
#  --group system:nodes

#kubectl describe configmap -n kube-system aws-auth
#############################################STEP 3###############################

#eksctl create iamserviceaccount \
#  --cluster "${CLUSTER_NAME}" --name karpenter --namespace $KARPENTER_NAMESPACE \
#  --role-name "${CLUSTER_NAME}-karpenter" \
#  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
#  --role-only \
#  --approve
#############################################STEP 4###############################

#eksctl get iamserviceaccount --cluster $CLUSTER_NAME --namespace $KARPENTER_NAMESPACE

#export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

#######  --set settings.isolatedVPC=true \ aws eks describe-cluster --name EKS-02 --query "cluster.resourcesVpcConfig" --output json
#Look for the following fields in the output:
#endpointPublicAccess: If true, the cluster is accessible publicly.
#endpointPrivateAccess: If true, the cluster is accessible privately.
#If only endpointPrivateAccess is true, your cluster is private.
#aws ec2 describe-internet-gateways --query "InternetGateways[*].Attachments"
#If the VPC associated with your EKS cluster has no IGW attached, it is isolated.

#############################################STEP 5###############################


#echo Your Karpenter version is: $KARPENTER_VERSION
#helm registry logout public.ecr.aws
#helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" \
#  --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
#  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
#  --set settings.clusterName=${CLUSTER_NAME} \
#  --set settings.clusterEndpoint=${CLUSTER_ENDPOINT} \
#  --set settings.featureGates.spotToSpotConsolidation=true \
#  --set settings.interruptionQueue=${CLUSTER_NAME} \
#  --set controller.resources.requests.cpu=1 \
#  --set controller.resources.requests.memory=1Gi \
#  --set controller.resources.limits.cpu=1 \
#  --set controller.resources.limits.memory=1Gi \
#  --set controller.env[0].name=KARPENTER_RESPECT_YUNIKORN_SCHEDULING \   ###if you are using yunikorn
#  --set controller.env[0].value=true   ###if you are using yunikorn
#  --debug \
#  --wait
#############################################STEP 6###############################
##HERE IS HAPPENING THAT WHEN KARPENTER IS INSTALLED, ALL CDRS POINTING TO KUBE-SYSTEM, WHICH IS WRONG, SO THE NAMESPACE MUST BE CHANGED
##kubectl edit crd nodeclaims.karpenter.sh
#kubectl edit crd nodepools.karpenter.sh
#kubectl edit crd ec2nodeclasses.karpenter.k8s.aws
##kubectl rollout restart deployment -n karpenter karpenter

##or
#SERVICE_NAME="karpenter"
#SERVICE_NAMESPACE="karpenter"
#SERVICE_PORT="8443"
#CRDS=("nodepools.karpenter.sh" "nodeclaims.karpenter.sh" "ec2nodeclasses.karpenter.k8s.aws")
#
#for crd in ${CRDS[@]}; do
#  kubectl patch customresourcedefinitions ${crd} --patch-file=/dev/stdin <<-EOF
#spec:
#  conversion:
#    webhook:
#      clientConfig:
#        service:
#          name: "${SERVICE_NAME}"
#          namespace: "${SERVICE_NAMESPACE}"
#          port: ${SERVICE_PORT}
#EOF
#done


#############################################STEP 6###############################

##helm list -n $KARPENTER_NAMESPACE
#There should be at least two pods karpenter-controller and karpenter-webhook
##kubectl get pods --namespace $KARPENTER_NAMESPACE -l app.kubernetes.io/name=karpenter
#There should be only one deployment Karpenter
#kubectl get deployment -n $KARPENTER_NAMESPACE -l app.kubernetes.io/name=karpenter




#############################################STEP 7###############################


#wget -O eks-node-viewer https://github.com/awslabs/eks-node-viewer/releases/download/v0.6.0/eks-node-viewer_Linux_x86_64
#chmod +x eks-node-viewer
#sudo mv -v eks-node-viewer /usr/local/bin
#eks-node-viewer

#It is essential to create a NodePool as Karpenter will remain inactive until at least one NodePool is configured

#aws iam create-instance-profile --instance-profile-name "KarpenterNodeInstanceProfile-EKS-02"
#aws iam add-role-to-instance-profile --instance-profile-name "KarpenterNodeInstanceProfile-EKS-02" --role-name "KarpenterNodeRole-EKS-02"
