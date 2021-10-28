# Makefile basic env setting
.DEFAULT_GOAL := help
# add pipefail support for default shell
SHELL := /bin/bash -o pipefail


# Project basic setting
project_name           ?= lua-resty-otp


# Hyperconverged Infrastructure
ENV_OS_NAME            ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
ENV_NGINX_EXEC         := $(shell which openresty 2>/dev/null || which nginx 2>/dev/null)
ENV_PROVE              ?= $(ENV_PROVE_ARGS) prove -I$(CURDIR)
ENV_PROVE_ARGS         ?= TEST_NGINX_BINARY=$(ENV_NGINX_EXEC)
ENV_PROVE_TARGET       ?= t


# Makefile basic extension function
_color_red    =\E[1;31m
_color_green  =\E[1;32m
_color_yellow =\E[1;33m
_color_blue   =\E[1;34m
_color_wipe   =\E[0m


define func_echo_status
	printf "[%b info %b] %s\n" "$(_color_blue)" "$(_color_wipe)" $(1)
endef


define func_echo_warn_status
	printf "[%b info %b] %s\n" "$(_color_yellow)" "$(_color_wipe)" $(1)
endef


define func_echo_success_status
	printf "[%b info %b] %s\n" "$(_color_green)" "$(_color_wipe)" $(1)
endef


# Makefile target
### help : Show Makefile rules
### 	If there're awk failures, please make sure
### 	you are using awk or gawk
.PHONY: help
help:
	@$(call func_echo_success_status, "Makefile rules:")
	@echo
	@if [ '$(ENV_OS_NAME)' = 'darwin' ]; then \
		awk '{ if(match($$0, /^#{3}([^:]+):(.*)$$/)){ split($$0, res, ":"); gsub(/^#{3}[ ]*/, "", res[1]); _desc=$$0; gsub(/^#{3}([^:]+):[ \t]*/, "", _desc); printf("    make %-15s : %-10s\n", res[1], _desc) } }' Makefile; \
	else \
		awk '{ if(match($$0, /^\s*#{3}\s*([^:]+)\s*:\s*(.*)$$/, res)){ printf("    make %-15s : %-10s\n", res[1], res[2]) } }' Makefile; \
	fi
	@echo



### unit test
### deps : Install unit test deps
.PHONY: deps
deps:
	@$(call func_echo_status, "$@ -> [ Start ]")
	./utils/install-deps.sh
	@$(call func_echo_success_status, "$@ -> [ Done ]")



### prove : Run unit test
.PHONY: prove
prove:
	@$(call func_echo_status, "$@ -> [ Start ]")
	@$(call func_echo_status, "$@ use default ENV_PROVE_TARGET: $(ENV_PROVE_TARGET)")
	$(ENV_PROVE) -r $(ENV_PROVE_TARGET)
	@$(call func_echo_success_status, "$@ -> [ Done ]")
