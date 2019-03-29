ifndef DEV_MK
DEV_MK:=# Prevent repeated "-include".

include ./make/verbose.mk

.PHONY: minishift-start
minishift-start:
	minishift start --cpus 4 --memory 8GB
	-eval `minishift docker-env` && oc login -u system:admin

# to watch all namespaces, keep namespace empty
APP_NAMESPACE ?= "app-test"
LOCAL_TEST_NAMESPACE ?= "local-test"

.PHONY: local-setup
## Creates a new project, aka namespace, in OpenShift
local-setup:
	$(Q)-oc new-project $(LOCAL_TEST_NAMESPACE)

.PHONY: local
## Run Operator locally
local: local-setup deploy-rbac build deploy-crd
	$(Q)operator-sdk up local --namespace=$(APP_NAMESPACE) # TODO(kwk): should this maybe be LOCAL_TEST_NAMESPACE?

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
	@-oc delete project $(LOCAL_TEST_NAMESPACE)

.PHONY: deploy-test
## Deploy a CR as test
deploy-test: local-setup
	$(Q)-oc apply -f examples/devopsconsole_v1alpha1_component_cr.yaml

endif
