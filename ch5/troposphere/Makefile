FILE_SRC ?= stack.py
FILE_OUT ?= template.yml
STACK_NAME ?= tropo-stack

.DEFAULT_TARGET: help

.PHONY: help
help:				## This help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: install_deps
install_deps:		## Install local dependencies.	
	@pip install -r requirements.txt


.PHONY: gen_cft
gen_cft:			## Generate CloudFormation template locally with Troposphere.
	@python $(FILE_SRC) >$(FILE_OUT)


.PHONY: deploy
deploy: gen_cft	## Run build_cft target and deploy stack from generated template.
	@aws cloudformation deploy --stack-name $(STACK_NAME) --template-file ./$(FILE_OUT)


.PHONY: destroy
destroy:			## Destroy stack. **WARNING: DESTRUCTIVE**
	@aws cloudformation delete-stack --stack-name $(STACK_NAME)


.PHONY: get_events
get_events:			## Get stack events
	@aws cloudformation describe-stack-events --stack-name $(STACK_NAME)