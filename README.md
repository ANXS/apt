## [ANXS](http://anxs.io/) - apt

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/anxs/apt/ci.yml)
![Maintenance](https://img.shields.io/maintenance/yes/2026.svg)
![Ansible Role](https://img.shields.io/ansible/role/d/anxs/apt)
![GitHub License](https://img.shields.io/github/license/anxs/apt)

Ansible role which executes apt-get update to ensure the local APT package cache is up to date. At the same time, it cleans it from packages and .deb files which are no longer needed. Also provides a variety of methods for processing system updates.

## Requirements & Dependencies

* Tested on Ansible 2.12 or higher.

## Variables

This is a partial listing of configurable variables.

* `apt_install_recommends` and `apt_install_suggests`, when set to `true`, will configure the system to automatically install recommended and/or suggested packagtes. Note this will have an impact of disk utilization.
* `apt_autoremove_recommends` and `apt_autoremove_suggests`, when set to `true` (the default), will have the inverse effect - removing these packages.
* `apt_source` will cause source repos to be included.
* `apt_upgrade`, when set to `true`, will perform some automatic upgrades during run time
  * `apt_upgrade_style` can be set to `full` or `dist`
  * `apt_upgrade_frequency` can be set to `once` to only do the upgrade once, `boot` for it to be reset after a reboot, and `always` for the system to always upgrade.

## Testing

This project uses molecule to test a few scenarios. You can kick off the tests (and linting) with `make test`.

#### Feedback, bug-reports, requests, ...

Are [welcome](https://github.com/ANXS/apt/issues)!
