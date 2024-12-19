CRDS="nodepools.karpenter.sh nodeclaims.karpenter.sh ec2nodeclasses.karpenter.k8s.aws"

for crd in $CRDS; do
  kubectl patch customresourcedefinitions "$crd" --patch-file=/dev/stdin <<EOF
spec:
  conversion:
    webhook:
      clientConfig:
        service:
          name: "karpenter"
          namespace: "karpenter"
          port: 8443
EOF
done

