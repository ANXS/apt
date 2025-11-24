.PHONY: requirements lint test test-all test-debian12 test-ubuntu2204 test-ubuntu2404 \
	test-matrix test-matrix-debian test-matrix-ubuntu2204 test-matrix-ubuntu2404

# set default jobs to be quarter of cores
NCORES := $(shell getconf _NPROCESSORS_ONLN)
RAW_JOBS := $(shell echo $(NCORES) \* 0.75 | bc)
JOBS := $(shell echo "scale=0; ($(RAW_JOBS) + 0.5) / 1" | bc)
ifeq ($(JOBS),0)
    JOBS := 1
endif
override MAKEFLAGS += --jobs=$(JOBS) --output-sync=target

requirements:
	pip install -q -r requirements-dev.txt

lint:
	yamllint -c .yamllint defaults tasks vars meta
	ansible-lint -c .ansible-lint defaults tasks vars meta

# Default basic test with upgrade disabled
test: requirements lint test-matrix

# OS-Specific Quick Tests (upgrade disabled)
test-debian12:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-quick \
		MOLECULE_SCENARIO_NAME=debian12-quick \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		molecule test

test-ubuntu2204:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-quick \
		MOLECULE_SCENARIO_NAME=ubuntu2204-quick \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		molecule test

test-ubuntu2404:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-quick \
		MOLECULE_SCENARIO_NAME=ubuntu2404-quick \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		molecule test

# Quick parallel test across all OS (upgrade disabled)
test-all: test-debian12 test-ubuntu2204 test-ubuntu2404

#
# Comprehensive Test Matrix
# -------------------------
# Tests all combinations of OS × upgrade settings
# Run with: make -j N test-matrix (where N is number of parallel jobs)
#

# Full matrix targets (30 total scenarios)
test-matrix: test-matrix-debian test-matrix-ubuntu2204 test-matrix-ubuntu2404

test-matrix-debian: \
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

#
# Individual Test Scenario Definitions
# -------------------------------------

# Debian 12 scenarios
test-debian12-upgrade-false:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-upgrade-false \
		MOLECULE_SCENARIO_NAME=debian12-upgrade-false \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=false \
		molecule test

test-debian12-safe-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-safe-once \
		MOLECULE_SCENARIO_NAME=debian12-safe-once \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		molecule test

test-debian12-safe-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-safe-boot \
		MOLECULE_SCENARIO_NAME=debian12-safe-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-debian12-safe-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-safe-always \
		MOLECULE_SCENARIO_NAME=debian12-safe-always \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		molecule test

test-debian12-full-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-full-once \
		MOLECULE_SCENARIO_NAME=debian12-full-once \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		molecule test

test-debian12-full-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-full-boot \
		MOLECULE_SCENARIO_NAME=debian12-full-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-debian12-full-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-full-always \
		MOLECULE_SCENARIO_NAME=debian12-full-always \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		molecule test

test-debian12-dist-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-dist-once \
		MOLECULE_SCENARIO_NAME=debian12-dist-once \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		molecule test

test-debian12-dist-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-dist-boot \
		MOLECULE_SCENARIO_NAME=debian12-dist-boot \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-debian12-dist-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/debian12-dist-always \
		MOLECULE_SCENARIO_NAME=debian12-dist-always \
		MOLECULE_OS=debian MOLECULE_VERSION=12 MOLECULE_IMAGE=geerlingguy/docker-debian12-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		molecule test

# Ubuntu 22.04 scenarios
test-ubuntu2204-upgrade-false:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-upgrade-false \
		MOLECULE_SCENARIO_NAME=ubuntu2204-upgrade-false \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=false \
		molecule test

test-ubuntu2204-safe-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-safe-once \
		MOLECULE_SCENARIO_NAME=ubuntu2204-safe-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		molecule test

test-ubuntu2204-safe-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-safe-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2204-safe-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-ubuntu2204-safe-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-safe-always \
		MOLECULE_SCENARIO_NAME=ubuntu2204-safe-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		molecule test

test-ubuntu2204-full-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-full-once \
		MOLECULE_SCENARIO_NAME=ubuntu2204-full-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		molecule test

test-ubuntu2204-full-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-full-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2204-full-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-ubuntu2204-full-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-full-always \
		MOLECULE_SCENARIO_NAME=ubuntu2204-full-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		molecule test

test-ubuntu2204-dist-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-dist-once \
		MOLECULE_SCENARIO_NAME=ubuntu2204-dist-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		molecule test

test-ubuntu2204-dist-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-dist-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2204-dist-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-ubuntu2204-dist-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2204-dist-always \
		MOLECULE_SCENARIO_NAME=ubuntu2204-dist-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2204 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2204-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		molecule test

# Ubuntu 24.04 scenarios
test-ubuntu2404-upgrade-false:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-upgrade-false \
		MOLECULE_SCENARIO_NAME=ubuntu2404-upgrade-false \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=false \
		molecule test

test-ubuntu2404-safe-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-safe-once \
		MOLECULE_SCENARIO_NAME=ubuntu2404-safe-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=once \
		molecule test

test-ubuntu2404-safe-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-safe-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2404-safe-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-ubuntu2404-safe-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-safe-always \
		MOLECULE_SCENARIO_NAME=ubuntu2404-safe-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=safe APT_UPGRADE_FREQUENCY=always \
		molecule test

test-ubuntu2404-full-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-full-once \
		MOLECULE_SCENARIO_NAME=ubuntu2404-full-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=once \
		molecule test

test-ubuntu2404-full-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-full-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2404-full-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-ubuntu2404-full-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-full-always \
		MOLECULE_SCENARIO_NAME=ubuntu2404-full-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=full APT_UPGRADE_FREQUENCY=always \
		molecule test

test-ubuntu2404-dist-once:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-dist-once \
		MOLECULE_SCENARIO_NAME=ubuntu2404-dist-once \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=once \
		molecule test

test-ubuntu2404-dist-boot:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-dist-boot \
		MOLECULE_SCENARIO_NAME=ubuntu2404-dist-boot \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=boot \
		molecule test

test-ubuntu2404-dist-always:
	MOLECULE_EPHEMERAL_DIRECTORY=.molecule-state/ubuntu2404-dist-always \
		MOLECULE_SCENARIO_NAME=ubuntu2404-dist-always \
		MOLECULE_OS=ubuntu MOLECULE_VERSION=2404 MOLECULE_IMAGE=geerlingguy/docker-ubuntu2404-ansible:latest \
		APT_UPGRADE=true APT_UPGRADE_STYLE=dist APT_UPGRADE_FREQUENCY=always \
		molecule test
