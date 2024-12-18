SHELL := /bin/bash


deploy: init \
 create-vpc

apply: create-vpc

init:
	terraform init

create-vpc:
	terraform apply -target="module.vpc" -auto-approve

.PHONY: *