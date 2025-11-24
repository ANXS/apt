import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ.get('MOLECULE_INVENTORY_FILE')).get_hosts('all')


def test_apt_conf_file(host):
    f = host.file('/etc/apt/apt.conf.d/10general')
    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root'
    assert f.mode in (0o644, 0o640)


def test_default_packages_installed(host):
    packages = ['apt-transport-https', 'ca-certificates']
    for pkg in packages:
        p = host.package(pkg)
        assert p.is_installed


def test_apt_update_cached(host):
    cmd = host.run('apt-cache policy')
    assert cmd.rc == 0


def test_sources_list_or_directory(host):
    """Test that apt sources are configured (either classic or deb822 format)."""
    # Debian 12+ uses /etc/apt/sources.list.d/ with .sources files
    # Older systems use /etc/apt/sources.list
    sources_file = host.file('/etc/apt/sources.list')
    sources_dir = host.file('/etc/apt/sources.list.d')

    # At least one method should exist
    assert sources_file.exists or sources_dir.is_directory


def test_upgrade_locks(host):
    """Test upgrade lock files based on environment configuration."""
    upgrade_enabled = os.environ.get('APT_UPGRADE', 'false').lower() == 'true'
    upgrade_frequency = os.environ.get('APT_UPGRADE_FREQUENCY', 'once')

    # If upgrades are explicitly disabled, ensure no lock files were created.
    if not upgrade_enabled:
        assert not host.file('/var/cache/anxs/apt-upgrade').exists
        assert not host.file('/var/run/anxs-apt-upgrade').exists
        return

    # When upgrade is enabled, check lock file behavior based on frequency
    if upgrade_frequency == 'once':
        # Should have created persistent lock file
        lock_file = host.file('/var/cache/anxs/apt-upgrade')
        assert lock_file.exists, "Expected lock file for 'once' frequency"
        assert lock_file.is_file
        # Should not have boot lock
        assert not host.file('/var/run/anxs-apt-upgrade').exists

    elif upgrade_frequency == 'boot':
        # Should have created boot-time lock file
        lock_file = host.file('/var/run/anxs-apt-upgrade')
        assert lock_file.exists, "Expected lock file for 'boot' frequency"
        assert lock_file.is_file
        # Should not have persistent lock
        assert not host.file('/var/cache/anxs/apt-upgrade').exists

    elif upgrade_frequency == 'always':
        # No lock files for 'always' (runs every time)
        assert not host.file('/var/cache/anxs/apt-upgrade').exists
        assert not host.file('/var/run/anxs-apt-upgrade').exists
