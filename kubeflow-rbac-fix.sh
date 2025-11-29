#!/bin/bash

# This script creates the missing ClusterRole and ClusterRoleBinding for the Kubeflow Profiles controller.
# This should resolve issues with creating user profiles and namespaces in Kubeflow.

echo "Creating ClusterRole 'manager-role'..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: manager-role
rules:
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - serviceaccounts
  verbs:
  - '*'
- apiGroups:
  - kubeflow.org
  resources:
  - profiles
  - profiles/finalizers
  - profiles/status
  verbs:
  - '*'
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - rolebindings
  verbs:
  - '*'
- apiGroups:
  - security.istio.io
  resources:
  - authorizationpolicies
  verbs:
  - '*'
EOF
echo "ClusterRole 'manager-role' created."

echo "Creating ClusterRoleBinding 'profiles-controller-binding'..."
kubectl create clusterrolebinding profiles-controller-binding --clusterrole=manager-role --serviceaccount=kubeflow:profiles-controller-service-account
echo "ClusterRoleBinding 'profiles-controller-binding' created."

echo "Restarting profiles-deployment to apply changes..."
kubectl rollout restart deployment -n kubeflow profiles-deployment
echo "Profiles deployment restarted. Please log out of Kubeflow and log back in."
echo "You can remove the 'manager-role.yaml' file after this if you wish."
