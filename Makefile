OUTPUT ?= daed
APPNAME ?= daed
VERSION ?= 0.0.0.unknown

.PHONY: submodules submodule rust-upstream-gate-local

daed:

all: clean daed

clean:
	rm -rf dist && rm -rf apps/web/dist && rm -f daed

## Begin Git Submodules
.gitmodules.d.mk: .gitmodules Makefile
	@set -e && \
	submodules=$$(grep '\[submodule "' .gitmodules | cut -d'"' -f2 | tr '\n' ' ' | tr ' \n' '\n' | sed 's/$$/\/.git/g') && \
	echo "submodule_ready=$${submodules}" > $@

-include .gitmodules.d.mk

$(submodule_ready): .gitmodules.d.mk
ifdef SKIP_SUBMODULES
	@echo "Skipping submodule update"
else
	git submodule update --init --recursive -- "$$(dirname $@)" && \
	touch $@
endif

submodule submodules: $(submodule_ready)
	@if [ -z "$(submodule_ready)" ]; then \
		rm -f .gitmodules.d.mk; \
		echo "Failed to generate submodules list. Please try again."; \
		exit 1; \
	fi
## End Git Submodules

## Begin Web
PFLAGS ?=
ifeq (,$(wildcard ./.git))
	PFLAGS += HUSKY=0
endif
dist: package.json pnpm-lock.yaml
	$(PFLAGS) pnpm i
	TURBO_TELEMETRY_DISABLED=1 DO_NOT_TRACK=1 pnpm build
	@if [ -d "apps/web/dist" ]; then \
		rm -rf dist; \
		cp -r apps/web/dist dist; \
	fi
## End Web

## Begin Bundle
DAE_WING_READY=wing/dae-core/control/bpf_bpfeb.o

$(DAE_WING_READY): wing
	cd wing && \
	$(MAKE) deps && \
	cd .. && \
	touch $@

daed: submodule $(DAE_WING_READY) dist
	cd wing && \
	$(MAKE) OUTPUT=../$(OUTPUT) APPNAME=$(APPNAME) WEB_DIST=../dist VERSION=$(VERSION) bundle
## End Bundle

rust-upstream-gate-local:
	@set -e; \
	tmp_go_mod=$$(mktemp); \
	cp wing/go.mod "$$tmp_go_mod"; \
	trap 'cp "$$tmp_go_mod" wing/go.mod; rm -f "$$tmp_go_mod" /tmp/daedrust-gate' EXIT; \
	sed 's#=> ../dae#=> ../../dae#' "$$tmp_go_mod" > wing/go.mod; \
	PATH=/root/.local/go1.25.9/bin:$$PATH $(MAKE) -C ../dae ebpf; \
	PATH=/root/.local/go1.25.9/bin:$$PATH $(MAKE) -C wing rust-upstream-gate-local; \
	pnpm check-types; \
	PATH=/root/.local/go1.25.9/bin:$$PATH $(MAKE) PFLAGS=HUSKY=0 OUTPUT=/tmp/daedrust-gate APPNAME=daedrust VERSION=local-rust-gate daed
