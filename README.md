## [ANXS](https://github.com/ANXS) - apt

[![CI Status](https://img.shields.io/github/actions/workflow/status/anxs/apt/ci.yml)](https://github.com/ANXS/apt/actions/workflows/ci.yml)
[![Maintenance](https://img.shields.io/maintenance/yes/2026.svg)](https://github.com/ANXS/apt)
[![Ansible Role](https://img.shields.io/ansible/role/d/anxs/apt)](https://galaxy.ansible.com/ui/standalone/roles/ANXS/apt/)
[![License](https://img.shields.io/github/license/ANXS/apt)](https://github.com/ANXS/apt/blob/master/LICENSE)

Ansible role for managing the APT package cache, cleaning up unneeded packages and .deb files, and optionally performing system upgrades with configurable frequency and style.

## Requirements & Dependencies

* Ansible 2.13 or higher.
* Ubuntu 20.04+ or Debian 11+.

## Variables

Some commonly adjusted variables. See [`defaults/main.yml`](https://github.com/ANXS/apt/blob/master/defaults/main.yml) for the full set.

* `apt_upgrade` (default `false`) controls whether automatic upgrades are done during the Ansible run.
  * `apt_upgrade_style` (default `safe`) controls the upgrade method. Other options are `full` and `dist`.
  * `apt_upgrade_frequency` (default `once`) affects how often the upgrade is run. Other options are `always` and (once per) `boot`.
* `apt_install_recommends` / `apt_install_suggests` (both default to `false`) allow installing recommended or suggested packages.
* `apt_autoremove` (default `true`) for  removing packages that are no longer needed/
* `apt_cache_valid_time` (default `3600`) to control how often APT cache is refreshed.

## Testing

Tests use [Molecule](https://github.com/ansible/molecule) with Docker and [Testinfra](https://testinfra.readthedocs.io/). Run the full suite with `make test`, or target a specific platform (e.g. `make test-ubuntu2404`). A comprehensive matrix covering upgrade style and frequency combinations is available via `make test-matrix`.

The test suite verifies APT configuration, required package installation, cache validity, upgrade execution and log parsing, lock file behavior across frequency modes, and OS-specific log format handling. Tests run across all supported Linux distributions.

## Note on AI Usage

This project has been developed with AI assistance. Contributions making use of AI generated content are welcome, however they _must_ be human reviewed prior to submission as pull requests, or issues. All contributors must be able to fully explain and defend any AI generated code, documentation, issues, or tests they submit. Contributions making use of AI must have this explicitly declared in the pull request or issue. This also applies to utilization of AI for reviewing of pull requests.

## Feedback, bug-reports, requests, ...

Are [welcome](https://github.com/ANXS/apt/issues)!
