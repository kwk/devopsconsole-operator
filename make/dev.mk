ifndef DEPLOY_MK
DEPLOY_MK:=# Prevent repeated "-include".

include ./make/verbose.mk

.PHONY: minishift-start
minishift-start:
	minishift start --cpus 4 --memory 8GB
	-eval `minishift docker-env` && oc login -u system:admin

# to watch all namespaces, keep namespace empty
OPERATOR_NAMESPACE ?= ""
APP_NAMESPACE ?= "app-test"

.PHONY: local-setup
## setup a project to deploy component CR
local-setup:
	$(Q)-oc new-project $(APP_NAMESPACE)

.PHONY: local
## Run Operator locally
local: local-setup deploy-rbac build deploy-crd
	$(Q)operator-sdk up local --namespace=$(OPERATOR_NAMESPACE)

.PHONY: deploy-rbac
## Setup service account and deploy RBAC
deploy-rbac:
	$(Q)-oc login -u system:admin
	$(Q)-oc apply -f deploy/service_account.yaml
	$(Q)-oc apply -f deploy/role.yaml
	$(Q)-oc apply -f deploy/role_binding.yaml

.PHONY: deploy-crd
## Deploy CRD
deploy-crd:
	$(Q)-oc apply -f deploy/crds/devopsconsole_v1alpha1_component_crd.yaml
	$(Q)-oc apply -f deploy/crds/devopsconsole_v1alpha1_gitsource_crd.yaml

.PHONY: deploy-operator
## Deploy Operator
deploy-operator: deploy-crd
	$(Q)oc create -f deploy/operator.yaml

.PHONY: deploy-clean
## Deploy a CR as test
deploy-clean:
	$(Q)-oc delete component.devopsconsole.openshift.io/myapp
	$(Q)-oc delete imagestream.image.openshift.io/myapp
	$(Q)-oc delete imagestream.image.openshift.io/nodejs
	$(Q)-oc delete buildconfig.build.openshift.io/myapp
	$(Q)-oc delete deploymentconfig.apps.openshift.io/myapp

.PHONY: deploy-test
## Deploy a CR as test
deploy-test: local-setup
	$(Q)oc create -f examples/devopsconsole_v1alpha1_component_cr.yaml

endif
