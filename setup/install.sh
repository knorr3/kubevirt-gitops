#!/bin/bash
NAMESPACE=${1:-kubevirt-hyperconverged}

oc create ns ${NAMESPACE}
oc adm policy add-role-to-user cluster-admin \
  system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller \
  -n ${NAMESPACE}

if [ ! -f repositories.yaml ]
then
    # Install repositories in to argocd config map
    GITREPO=$(git remote -v | awk -F '[:/ ]' '/origin.*push/ {print $(NF-2) "/" $(NF-1)}')
    cat > repositories.yaml <<END
 - type: git
   url: https://github.com/${GITREPO}
END
fi

oc -n openshift-gitops create cm argocd-cm --from-file=repositories=repositories.yaml --dry-run=client -o yaml | oc apply -f -
