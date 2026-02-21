.PHONY: lint test test-all test-debian11 test-debian12 test-debian13 test-ubuntu2004 test-ubuntu2204 test-ubuntu2404 \
	test-matrix test-matrix-debian11 test-matrix-debian12 test-matrix-debian13 \
	test-matrix-ubuntu2004 test-matrix-ubuntu2204 test-matrix-ubuntu2404 \
	act act-download clean distclean

VENV := .venv
BIN := $(VENV)/bin
export PATH := $(CURDIR)/$(BIN):$(PATH)

$(VENV): requirements-dev.txt
	python3 -m venv $(VENV)
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install -r requirements-dev.txt
	@touch $(VENV)

lint: $(VENV)
	$(BIN)/yamllint -c .yamllint defaults tasks vars meta
	$(BIN)/ansible-lint -c .ansible-lint defaults tasks vars meta

test: lint test-all

# OS-Specific Quick Tests (upgrade disabled)
test-debian11: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-quick \
		MOLECULE_SCENARIO_NAME=debian11-quick \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		$(BIN)/molecule test

test-debian13: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-quick \
		MOLECULE_SCENARIO_NAME=debian13-quick \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		$(BIN)/molecule test

test-debian12: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-quick \
		MOLECULE_SCENARIO_NAME=debian12-quick \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		$(BIN)/molecule test

test-ubuntu2004: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-quick \
		MOLECULE_SCENARIO_NAME=ubuntu2004-quick \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		$(BIN)/molecule test

test-ubuntu2204: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-quick \
		MOLECULE_SCENARIO_NAME=ubuntu2204-quick \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		$(BIN)/molecule test

test-ubuntu2404: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-quick \
		MOLECULE_SCENARIO_NAME=ubuntu2404-quick \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		$(BIN)/molecule test

test-all: test-debian11 test-debian12 test-debian13 test-ubuntu2004 test-ubuntu2204 test-ubuntu2404

#
# Comprehensive Test Matrix
# -------------------------
# Tests all combinations of OS x upgrade settings
# 6 OS x 10 configs = 60 scenarios
#

test-matrix: test-matrix-debian11 test-matrix-debian12 test-matrix-debian13 \
	test-matrix-ubuntu2004 test-matrix-ubuntu2204 test-matrix-ubuntu2404

# --- Debian 11 ---
test-matrix-debian11: \
	test-debian11-upgrade-false \
	test-debian11-safe-once \
	test-debian11-safe-boot \
	test-debian11-safe-always \
	test-debian11-full-once \
	test-debian11-full-boot \
	test-debian11-full-always \
	test-debian11-dist-once \
	test-debian11-dist-boot \
	test-debian11-dist-always

test-debian11-upgrade-false: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-upgrade-false \
		MOLECULE_SCENARIO_NAME=debian11-upgrade-false \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=false \
		$(BIN)/molecule test

test-debian11-safe-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-safe-once \
		MOLECULE_SCENARIO_NAME=debian11-safe-once \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian11-safe-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-safe-boot \
		MOLECULE_SCENARIO_NAME=debian11-safe-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian11-safe-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-safe-always \
		MOLECULE_SCENARIO_NAME=debian11-safe-always \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-debian11-full-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-full-once \
		MOLECULE_SCENARIO_NAME=debian11-full-once \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian11-full-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-full-boot \
		MOLECULE_SCENARIO_NAME=debian11-full-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian11-full-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-full-always \
		MOLECULE_SCENARIO_NAME=debian11-full-always \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-debian11-dist-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-dist-once \
		MOLECULE_SCENARIO_NAME=debian11-dist-once \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian11-dist-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-dist-boot \
		MOLECULE_SCENARIO_NAME=debian11-dist-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian11-dist-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian11-dist-always \
		MOLECULE_SCENARIO_NAME=debian11-dist-always \
		MOLECULE_OS=debian MOLECULE_VERSION=11 MOLECULE_IMAGE=geerlingguy/docker-debian11-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

# --- Debian 12 ---
test-matrix-debian12: \
	test-debian12-upgrade-false \
	test-debian12-safe-once \
	test-debian12-safe-boot \
	test-debian12-safe-always \
	test-debian12-full-once \
	test-debian12-full-boot \
	test-debian12-full-always \
	test-debian12-dist-once \
	test-debian12-dist-boot \
	test-debian12-dist-always

test-debian12-upgrade-false: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-upgrade-false \
		MOLECULE_SCENARIO_NAME=debian12-upgrade-false \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=false \
		$(BIN)/molecule test

test-debian12-safe-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-safe-once \
		MOLECULE_SCENARIO_NAME=debian12-safe-once \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian12-safe-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-safe-boot \
		MOLECULE_SCENARIO_NAME=debian12-safe-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian12-safe-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-safe-always \
		MOLECULE_SCENARIO_NAME=debian12-safe-always \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-debian12-full-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-full-once \
		MOLECULE_SCENARIO_NAME=debian12-full-once \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian12-full-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-full-boot \
		MOLECULE_SCENARIO_NAME=debian12-full-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian12-full-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-full-always \
		MOLECULE_SCENARIO_NAME=debian12-full-always \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-debian12-dist-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-dist-once \
		MOLECULE_SCENARIO_NAME=debian12-dist-once \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian12-dist-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-dist-boot \
		MOLECULE_SCENARIO_NAME=debian12-dist-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian12-dist-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-dist-always \
		MOLECULE_SCENARIO_NAME=debian12-dist-always \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

# --- Debian 13 ---
test-matrix-debian13: \
	test-debian13-upgrade-false \
	test-debian13-safe-once \
	test-debian13-safe-boot \
	test-debian13-safe-always \
	test-debian13-full-once \
	test-debian13-full-boot \
	test-debian13-full-always \
	test-debian13-dist-once \
	test-debian13-dist-boot \
	test-debian13-dist-always

test-debian13-upgrade-false: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-upgrade-false \
		MOLECULE_SCENARIO_NAME=debian13-upgrade-false \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=false \
		$(BIN)/molecule test

test-debian13-safe-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-safe-once \
		MOLECULE_SCENARIO_NAME=debian13-safe-once \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian13-safe-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-safe-boot \
		MOLECULE_SCENARIO_NAME=debian13-safe-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian13-safe-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-safe-always \
		MOLECULE_SCENARIO_NAME=debian13-safe-always \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-debian13-full-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-full-once \
		MOLECULE_SCENARIO_NAME=debian13-full-once \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian13-full-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-full-boot \
		MOLECULE_SCENARIO_NAME=debian13-full-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian13-full-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-full-always \
		MOLECULE_SCENARIO_NAME=debian13-full-always \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-debian13-dist-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-dist-once \
		MOLECULE_SCENARIO_NAME=debian13-dist-once \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-debian13-dist-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-dist-boot \
		MOLECULE_SCENARIO_NAME=debian13-dist-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-debian13-dist-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian13-dist-always \
		MOLECULE_SCENARIO_NAME=debian13-dist-always \
		MOLECULE_OS=debian MOLECULE_VERSION=13 MOLECULE_IMAGE=geerlingguy/docker-debian13-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

# --- Ubuntu 20.04 ---
test-matrix-ubuntu2004: \
	test-ubuntu2004-upgrade-false \
	test-ubuntu2004-safe-once \
	test-ubuntu2004-safe-boot \
	test-ubuntu2004-safe-always \
	test-ubuntu2004-full-once \
	test-ubuntu2004-full-boot \
	test-ubuntu2004-full-always \
	test-ubuntu2004-dist-once \
	test-ubuntu2004-dist-boot \
	test-ubuntu2004-dist-always

test-ubuntu2004-upgrade-false: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-upgrade-false \
		MOLECULE_SCENARIO_NAME=ubuntu2004-upgrade-false \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=false \
		$(BIN)/molecule test

test-ubuntu2004-safe-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-safe-once \
		MOLECULE_SCENARIO_NAME=ubuntu2004-safe-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2004-safe-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-safe-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2004-safe-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2004-safe-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-safe-always \
		MOLECULE_SCENARIO_NAME=ubuntu2004-safe-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-ubuntu2004-full-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-full-once \
		MOLECULE_SCENARIO_NAME=ubuntu2004-full-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2004-full-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-full-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2004-full-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2004-full-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-full-always \
		MOLECULE_SCENARIO_NAME=ubuntu2004-full-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-ubuntu2004-dist-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-dist-once \
		MOLECULE_SCENARIO_NAME=ubuntu2004-dist-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2004-dist-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-dist-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2004-dist-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2004-dist-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2004-dist-always \
		MOLECULE_SCENARIO_NAME=ubuntu2004-dist-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2004 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2004-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

# --- Ubuntu 22.04 ---
test-matrix-ubuntu2204: \
	test-ubuntu2204-upgrade-false \
	test-ubuntu2204-safe-once \
	test-ubuntu2204-safe-boot \
	test-ubuntu2204-safe-always \
	test-ubuntu2204-full-once \
	test-ubuntu2204-full-boot \
	test-ubuntu2204-full-always \
	test-ubuntu2204-dist-once \
	test-ubuntu2204-dist-boot \
	test-ubuntu2204-dist-always

test-ubuntu2204-upgrade-false: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-upgrade-false \
		MOLECULE_SCENARIO_NAME=ubuntu2204-upgrade-false \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=false \
		$(BIN)/molecule test

test-ubuntu2204-safe-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-safe-once \
		MOLECULE_SCENARIO_NAME=ubuntu2204-safe-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2204-safe-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-safe-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2204-safe-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2204-safe-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-safe-always \
		MOLECULE_SCENARIO_NAME=ubuntu2204-safe-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-ubuntu2204-full-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-full-once \
		MOLECULE_SCENARIO_NAME=ubuntu2204-full-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2204-full-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-full-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2204-full-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2204-full-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-full-always \
		MOLECULE_SCENARIO_NAME=ubuntu2204-full-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-ubuntu2204-dist-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-dist-once \
		MOLECULE_SCENARIO_NAME=ubuntu2204-dist-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2204-dist-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-dist-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2204-dist-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2204-dist-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-dist-always \
		MOLECULE_SCENARIO_NAME=ubuntu2204-dist-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

# --- Ubuntu 24.04 ---
test-matrix-ubuntu2404: \
	test-ubuntu2404-upgrade-false \
	test-ubuntu2404-safe-once \
	test-ubuntu2404-safe-boot \
	test-ubuntu2404-safe-always \
	test-ubuntu2404-full-once \
	test-ubuntu2404-full-boot \
	test-ubuntu2404-full-always \
	test-ubuntu2404-dist-once \
	test-ubuntu2404-dist-boot \
	test-ubuntu2404-dist-always

test-ubuntu2404-upgrade-false: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-upgrade-false \
		MOLECULE_SCENARIO_NAME=ubuntu2404-upgrade-false \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=false \
		$(BIN)/molecule test

test-ubuntu2404-safe-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-safe-once \
		MOLECULE_SCENARIO_NAME=ubuntu2404-safe-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2404-safe-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-safe-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2404-safe-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2404-safe-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-safe-always \
		MOLECULE_SCENARIO_NAME=ubuntu2404-safe-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-ubuntu2404-full-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-full-once \
		MOLECULE_SCENARIO_NAME=ubuntu2404-full-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2404-full-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-full-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2404-full-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2404-full-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-full-always \
		MOLECULE_SCENARIO_NAME=ubuntu2404-full-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

test-ubuntu2404-dist-once: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-dist-once \
		MOLECULE_SCENARIO_NAME=ubuntu2404-dist-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		$(BIN)/molecule test

test-ubuntu2404-dist-boot: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-dist-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2404-dist-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		$(BIN)/molecule test

test-ubuntu2404-dist-always: $(VENV)
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-dist-always \
		MOLECULE_SCENARIO_NAME=ubuntu2404-dist-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		$(BIN)/molecule test

# --- act (local GitHub workflow testing) ---
ACT_VERSION ?= 0.2.82
ACT_BINARY := $(CURDIR)/.act/act

act-download:
	@if [ ! -f "$(ACT_BINARY)" ]; then \
		echo "Downloading act v$(ACT_VERSION)..." ; \
		mkdir -p $(CURDIR)/.act ; \
		curl -sL https://github.com/nektos/act/releases/download/v$(ACT_VERSION)/act_Linux_x86_64.tar.gz | tar -xz -C $(CURDIR)/.act act ; \
	fi

act: act-download
	$(ACT_BINARY)

clean:
	$(BIN)/molecule destroy 2>/dev/null || true

distclean: clean
	rm -rf $(VENV) .act
