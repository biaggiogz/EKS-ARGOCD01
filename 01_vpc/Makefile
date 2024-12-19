SHELL := /bin/bash

deployvpc:
	terraform init
	terraform apply -target="module.vpc" -auto-approve

destroyvpc:
	terraform destroy -target="module.vpc" -auto-approve

.PHONY: deployvpc destroyvpc
