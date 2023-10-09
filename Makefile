# binary aliases
TF=terraform -chdir=./infrastructure/
WEBPACK=./node_modules/.bin/webpack
SHELL:=/bin/bash -O globstar

# variables
PROJECT=api-core
ENVIRONMENT=dev

##@ Dependencies
.PHONY: install install-tools

install: install-tools ## Install all dependencies

install-tools: ## Install tooling
	asdf install

##@ Lint
.PHONY: lint lint-fix lint-tf lint-tf-fix

lint: lint-tf ## Run all linters

lint-fix: lint-tf-fix ## Attempt to automagically fiax all linting issues

lint-tf: ## Lint terraform code
	@echo "Linting Terraform"
	$(TF) validate
	$(TF) init -backend=false
	$(TF) fmt -check -recursive

lint-tf-fix: ## Auto fix terraform linting errors
	@echo "Fixing Terraform linting"
	$(TF) init -backend=false
	$(TF) fmt -recursive

##@ Build
.PHONY: build build-functions

build: build-functions ## Build everything

build-functions: ## Build lambda functions
	@echo "Building lambda functions"
	rm -r ./dist/*
	$(WEBPACK)
	cd dist && for i in *.js; do cp "$$i" index.js && zip "$${i%.js*}.zip" index.js && rm index.js; done

##@ Deployment
.PHONY: deploy tf-init tf-plan tf-apply

deploy: tf-plan tf-apply ## Full deployment

tf-init: ## Initialise terraform
	@echo "Initialising terraform"
	$(TF) init
	$(TF) workspace select -or-create=true ${ENVIRONMENT} 

tf-plan: ## Plan terraform changeset
	@echo "Creating terraform plan"
	$(TF) workspace select ${ENVIRONMENT}
	$(TF) plan -input=false -out=./${PROJECT}.tfplan

tf-apply: ## Apply terraform changeset
	@echo "Applying terraform plan"
	$(TF) workspace select ${ENVIRONMENT}
	$(TF) apply -input=false -auto-approve ./${PROJECT}.tfplan

##@ Helpers
.PHONY: help update-certs

update-certs: ## Update the cloudflare CA public certs
	@echo "Downloading Cloudflare CA cert chain"
	curl https://developers.cloudflare.com/ssl/static/origin_ca_ecc_root.pem > cloudflare_origin_root_ca.pem

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)