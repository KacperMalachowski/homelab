# Homelab task runner. Wraps the OpenTofu / Packer / lint commands used in CI so
# they can be run locally without memorizing flags. See CLAUDE.md for context.

TF_DIR   ?= terraform/environments/prod
PKR_DIR  ?= packer/microos/hcloud
ANSIBLE_DIR ?= ansible
LOCK_TIMEOUT ?= 300s

TOFU := tofu -chdir=$(TF_DIR)

.DEFAULT_GOAL := help

.PHONY: help
help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

## --- OpenTofu ---

.PHONY: init
init: ## tofu init (no prompts)
	$(TOFU) init -input=false

.PHONY: fmt
fmt: ## Format all *.tf recursively
	tofu fmt -recursive

.PHONY: fmt-check
fmt-check: ## Check formatting without writing (CI gate)
	tofu fmt -check -recursive

.PHONY: validate
validate: init ## tofu validate
	$(TOFU) validate

.PHONY: plan
plan: ## tofu plan
	$(TOFU) plan -input=false -lock-timeout=$(LOCK_TIMEOUT)

.PHONY: apply
apply: ## tofu apply (auto-approve, as CI runs it)
	$(TOFU) apply -auto-approve -lock-timeout=$(LOCK_TIMEOUT)

.PHONY: drift
drift: ## Drift check (non-zero exit when plan is non-empty)
	$(TOFU) plan -input=false -detailed-exitcode -lock-timeout=$(LOCK_TIMEOUT)

## --- Lint ---

.PHONY: lint
lint: ## tflint (init plugins, then run) in the tofu dir
	cd $(TF_DIR) && tflint --init && tflint

.PHONY: lint-ansible
lint-ansible: ## ansible-lint over the ansible dir
	ansible-lint $(ANSIBLE_DIR)

.PHONY: check
check: fmt-check validate lint ## Pre-PR: format check + validate + tflint

## --- Packer ---

.PHONY: snapshot
snapshot: ## Build the k3s MicroOS snapshot (override: make snapshot NAME_SUFFIX=pr123)
	cd $(PKR_DIR) && packer init . && packer build -var "name_suffix=$(NAME_SUFFIX)" .
