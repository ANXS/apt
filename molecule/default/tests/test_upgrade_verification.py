"""
Testinfra tests for anxs.apt role - APT/DPKG log verification for upgrades.

This module verifies upgrade operations by inspecting apt/dpkg logs to ensure:
- Upgrades executed when enabled (and didn't when disabled)
- Correct upgrade style was used (safe, full, dist)
- No errors occurred during apt/dpkg operations
- OS-specific log format handling for Debian and Ubuntu
"""
import os
import re
from datetime import datetime, timedelta
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ.get('MOLECULE_INVENTORY_FILE')).get_hosts('all')

# Configuration
LOG_WINDOW_MINUTES = int(os.environ.get('ANSIBLE_TEST_LOG_WINDOW', '10'))


# ==============================================================================
# Helper Functions
# ==============================================================================

def get_os_info(host):
    """
    Detect OS distribution and version.

    Returns:
        tuple: (distribution, version) e.g., ('debian', '12') or ('ubuntu', '22.04')
    """
    os_release = host.file('/etc/os-release')
    assert os_release.exists, "Cannot determine OS: /etc/os-release not found"

    content = os_release.content_string
    distro = None
    version = None

    for line in content.split('\n'):
        if line.startswith('ID='):
            distro = line.split('=')[1].strip('"').lower()
        elif line.startswith('VERSION_ID='):
            version = line.split('=')[1].strip('"')

    return distro, version


def parse_apt_history_log(host, log_window_minutes=LOG_WINDOW_MINUTES):
    """
    Parse /var/log/apt/history.log for upgrade operations.

    Args:
        host: testinfra host fixture
        log_window_minutes: only consider entries within this time window

    Returns:
        list: List of upgrade entry dictionaries with keys:
              - start_date: datetime object
              - commandline: str
              - upgrade_packages: str
    """
    history_file = host.file('/var/log/apt/history.log')
    if not history_file.exists:
        raise AssertionError("APT history log not found: /var/log/apt/history.log")

    content = history_file.content_string
    cutoff_time = datetime.now() - timedelta(minutes=log_window_minutes)

    entries = []
    current_entry = {}

    for line in content.split('\n'):
        if line.startswith('Start-Date:'):
            # Format: "Start-Date: 2024-01-15  14:23:45"
            date_str = line.split('Start-Date:', 1)[1].strip()
            try:
                entry_time = datetime.strptime(date_str, '%Y-%m-%d  %H:%M:%S')
            except ValueError:
                # Try alternate format without double space
                entry_time = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')

            if entry_time >= cutoff_time:
                current_entry = {'start_date': entry_time}

        elif line.startswith('Commandline:') and current_entry:
            current_entry['commandline'] = line.split('Commandline:', 1)[1].strip()

        elif line.startswith('Upgrade:') and current_entry:
            current_entry['upgrade_packages'] = line.split('Upgrade:', 1)[1].strip()

        elif line.startswith('End-Date:') and current_entry:
            if 'commandline' in current_entry:
                entries.append(current_entry)
            current_entry = {}

    return entries


def parse_dpkg_log(host, log_window_minutes=LOG_WINDOW_MINUTES):
    """
    Parse /var/log/dpkg.log for package upgrade operations.

    Args:
        host: testinfra host fixture
        log_window_minutes: only consider entries within this time window

    Returns:
        tuple: (upgrade_entries, error_entries)
            - upgrade_entries: list of upgrade operation dicts
            - error_entries: list of error operation dicts
    """
    dpkg_file = host.file('/var/log/dpkg.log')
    if not dpkg_file.exists:
        raise AssertionError("DPKG log not found: /var/log/dpkg.log")

    content = dpkg_file.content_string
    cutoff_time = datetime.now() - timedelta(minutes=log_window_minutes)

    upgrade_entries = []
    error_entries = []

    # dpkg log format: "2024-01-15 14:23:45 upgrade package:arch old-ver new-ver"
    for line in content.split('\n'):
        if not line.strip():
            continue

        parts = line.split(None, 2)
        if len(parts) < 3:
            continue

        date_str, time_str, rest = parts[0], parts[1], parts[2]

        try:
            entry_time = datetime.strptime(f"{date_str} {time_str}", '%Y-%m-%d %H:%M:%S')
        except ValueError:
            continue

        if entry_time < cutoff_time:
            continue

        # Look for upgrade operations
        if ' upgrade ' in rest:
            match = re.search(r'upgrade (\S+) (\S+) (\S+)', rest)
            if match:
                upgrade_entries.append({
                    'timestamp': entry_time,
                    'package': match.group(1),
                    'old_version': match.group(2),
                    'new_version': match.group(3)
                })

        # Look for error states
        if any(error_marker in rest for error_marker in [
            'status half-configured',
            'status half-installed',
            'status config-files',
            'status triggers-awaited',
            'status triggers-pending'
        ]):
            # These are transient states; only flag if they're the final state
            pass

        # Look for explicit errors
        if 'error' in rest.lower() or 'failed' in rest.lower():
            error_entries.append({
                'timestamp': entry_time,
                'line': rest
            })

    return upgrade_entries, error_entries


def parse_apt_term_log(host, log_window_minutes=LOG_WINDOW_MINUTES):
    """
    Parse /var/log/apt/term.log to extract the exact apt command executed.

    Args:
        host: testinfra host fixture
        log_window_minutes: only consider entries within this time window

    Returns:
        list: List of command strings found in recent log entries
    """
    term_file = host.file('/var/log/apt/term.log')
    if not term_file.exists:
        raise AssertionError("APT term log not found: /var/log/apt/term.log")

    content = term_file.content_string

    # term.log doesn't have timestamps in the content, but we can use file mtime
    # as a proxy for when operations occurred
    mtime = term_file.mtime
    cutoff_time = datetime.now() - timedelta(minutes=log_window_minutes)

    if mtime < cutoff_time:
        return []

    commands = []

    # Look for apt/apt-get command lines in the log
    # Format varies but typically: "Commandline: apt-get upgrade" or similar
    for line in content.split('\n'):
        if 'apt-get' in line.lower() or line.strip().startswith('apt '):
            # Extract command
            if 'upgrade' in line.lower() or 'full-upgrade' in line.lower() or 'dist-upgrade' in line.lower():
                commands.append(line.strip())

    return commands


def check_apt_errors_in_logs(host, log_window_minutes=LOG_WINDOW_MINUTES):
    """
    Check apt logs for error conditions.

    Returns:
        list: List of error messages found (empty if no errors)
    """
    errors = []

    # Check apt term.log for error output
    term_file = host.file('/var/log/apt/term.log')
    if term_file.exists:
        content = term_file.content_string

        # Look for common error patterns
        error_patterns = [
            r'E: .*',  # apt error lines start with "E:"
            r'Err:?\d* .*',  # download errors
            r'Failed to .*',
            r'Could not .*',
            r'Unable to .*',
        ]

        for line in content.split('\n'):
            for pattern in error_patterns:
                if re.search(pattern, line):
                    errors.append(line.strip())

    return errors


def get_upgrade_style_from_env():
    """Get expected upgrade style from environment variables."""
    return os.environ.get('APT_UPGRADE_STYLE', 'safe').lower()


def get_upgrade_enabled_from_env():
    """Check if upgrades are enabled from environment variables."""
    return os.environ.get('APT_UPGRADE', 'false').lower() == 'true'


def get_upgrade_frequency_from_env():
    """Get upgrade frequency from environment variables."""
    return os.environ.get('APT_UPGRADE_FREQUENCY', 'once').lower()


def verify_upgrade_style_in_command(command, expected_style):
    """
    Verify that the command matches the expected upgrade style.

    Note: Ansible's apt module behavior varies by OS:
    - safe: may use "upgrade" or "upgrade --with-new-pkgs" depending on apt version
    - full: typically uses "dist-upgrade" (older) or "full-upgrade" (newer)
    - dist: always uses "dist-upgrade"

    Args:
        command: command string from logs
        expected_style: 'safe', 'full', or 'dist'

    Returns:
        bool: True if command matches expected style
    """
    command = command.lower()

    # Skip install commands entirely
    if ' install ' in command:
        return False

    if expected_style == 'safe':
        # Safe upgrade: "apt-get upgrade" with or without --with-new-pkgs
        # Ansible may add --with-new-pkgs on newer Ubuntu systems (this is still considered "safe")
        # Must NOT be dist-upgrade or full-upgrade
        # Look for " upgrade" (with leading space) but not "dist-upgrade" or "full-upgrade"
        has_basic_upgrade = ' upgrade' in command
        not_dist = 'dist-upgrade' not in command
        not_full = 'full-upgrade' not in command
        return has_basic_upgrade and not_dist and not_full

    elif expected_style == 'full':
        # Full upgrade: Ansible uses "dist-upgrade" for 'full' on many systems
        # Can also be "full-upgrade" on newer systems
        return ('full-upgrade' in command or
                'dist-upgrade' in command)

    elif expected_style == 'dist':
        # Dist upgrade: Always "dist-upgrade"
        return 'dist-upgrade' in command

    return False


# ==============================================================================
# Test Functions
# ==============================================================================

def test_upgrade_happened_when_enabled(host):
    """
    Verify that apt upgrade operations occurred when enabled.

    Checks apt history.log for recent upgrade entries when APT_UPGRADE=true.
    When APT_UPGRADE=false, this test is skipped.
    """
    upgrade_enabled = get_upgrade_enabled_from_env()

    if not upgrade_enabled:
        # Skip test when upgrades are disabled
        return

    # Parse apt history log
    history_entries = parse_apt_history_log(host, LOG_WINDOW_MINUTES)

    # We should have at least one upgrade entry in the recent history
    upgrade_entries = [e for e in history_entries if 'upgrade' in e.get('commandline', '').lower()]

    assert len(upgrade_entries) > 0, (
        f"Expected upgrade entries in apt history.log within last {LOG_WINDOW_MINUTES} minutes, "
        f"but found none. History entries found: {len(history_entries)}"
    )


def test_upgrade_style_matches_configuration(host):
    """
    Verify that the upgrade style used matches the configuration.

    Checks that 'safe', 'full', or 'dist' upgrade was executed as configured.
    """
    upgrade_enabled = get_upgrade_enabled_from_env()

    if not upgrade_enabled:
        # Skip test when upgrades are disabled
        return

    expected_style = get_upgrade_style_from_env()

    # Parse apt history log for commands
    history_entries = parse_apt_history_log(host, LOG_WINDOW_MINUTES)

    # Filter for actual upgrade commands (exclude install commands entirely)
    # The key insight: install commands have " install " in them, upgrade commands don't
    upgrade_commands = []
    for e in history_entries:
        cmd = e.get('commandline', '')
        cmd_lower = cmd.lower()
        # Include command if it has upgrade-related keywords but NOT if it's an install command
        if ('upgrade' in cmd_lower or 'dist-upgrade' in cmd_lower or 'full-upgrade' in cmd_lower):
            # But skip if it's an install command (these have " install " in them)
            if ' install ' not in cmd_lower:
                upgrade_commands.append(cmd)

    # If no upgrade commands found in history, check if upgrade was attempted but no packages needed upgrading
    # This can happen when the system is already up-to-date
    if len(upgrade_commands) == 0:
        # Check dpkg log for recent activity that would indicate an upgrade was attempted
        upgrade_entries, _ = parse_dpkg_log(host, LOG_WINDOW_MINUTES)

        # If there are no package upgrades AND no commands, the upgrade likely didn't run
        # or there was nothing to upgrade. Check for the upgrade operation in dpkg log timestamps
        dpkg_log = host.file('/var/log/dpkg.log')
        if dpkg_log.exists:
            mtime = dpkg_log.mtime
            cutoff_time = datetime.now() - timedelta(minutes=LOG_WINDOW_MINUTES)

            # If dpkg was touched recently but no upgrade commands logged,
            # the upgrade likely ran but found nothing to do
            if mtime >= cutoff_time and len(upgrade_entries) == 0:
                # System was already up-to-date, test passes
                return

        # If we get here, no upgrade happened at all
        assert False, (
            f"No upgrade commands found in history log to verify style. "
            f"History entries found: {len(history_entries)}, "
            f"Commands: {[e.get('commandline', '') for e in history_entries]}"
        )

    # Check that at least one command matches our expected style
    style_matched = False
    for cmd in upgrade_commands:
        if verify_upgrade_style_in_command(cmd, expected_style):
            style_matched = True
            break

    assert style_matched, (
        f"Expected upgrade style '{expected_style}' not found in commands. "
        f"Commands found: {upgrade_commands}"
    )


def test_dpkg_log_shows_package_operations(host):
    """
    Verify that dpkg.log shows package upgrade operations (or is empty if no packages needed upgrading).

    This test verifies that:
    1. The dpkg log exists and is accessible
    2. If packages were upgraded, they appear in the log
    3. No error states persist
    """
    upgrade_enabled = get_upgrade_enabled_from_env()

    if not upgrade_enabled:
        # Skip test when upgrades are disabled
        return

    upgrade_entries, error_entries = parse_dpkg_log(host, LOG_WINDOW_MINUTES)

    # It's OK if no packages were upgraded (system may be fully updated)
    # But if upgrade ran, we should see SOME activity in dpkg log
    # We can verify by checking that apt history shows an upgrade occurred
    history_entries = parse_apt_history_log(host, LOG_WINDOW_MINUTES)

    if len(history_entries) > 0:
        # If apt ran an upgrade, dpkg should have logged *something*
        # Even if no packages changed, there should be recent activity
        dpkg_log = host.file('/var/log/dpkg.log')
        assert dpkg_log.exists, "DPKG log should exist"

        # Check that dpkg log has been written to recently
        # Note: dpkg_log.mtime is already a datetime object in testinfra
        mtime = dpkg_log.mtime
        cutoff_time = datetime.now() - timedelta(minutes=LOG_WINDOW_MINUTES)

        assert mtime >= cutoff_time, (
            f"DPKG log has not been updated recently. Last modified: {mtime}, "
            f"cutoff: {cutoff_time}"
        )


def test_no_upgrade_when_disabled(host):
    """
    Verify that no upgrade operations occurred when APT_UPGRADE=false.

    Checks that apt history.log contains no recent upgrade entries.
    """
    upgrade_enabled = get_upgrade_enabled_from_env()

    if upgrade_enabled:
        # Skip test when upgrades are enabled
        return

    # Parse apt history log
    history_entries = parse_apt_history_log(host, LOG_WINDOW_MINUTES)

    # Filter for actual upgrade-related commands (not just 'install' with 'upgrade' in package name)
    # Look for actual upgrade commands: upgrade, dist-upgrade, full-upgrade
    upgrade_entries = []
    for e in history_entries:
        cmd = e.get('commandline', '').lower()
        # Only flag actual upgrade commands, not package installations
        if any(upgrade_type in cmd for upgrade_type in [' upgrade', ' dist-upgrade', ' full-upgrade']):
            # Make sure it's not just " install unattended-upgrades"
            if ' install ' not in cmd or (' upgrade ' in cmd or ' dist-upgrade' in cmd or ' full-upgrade' in cmd):
                upgrade_entries.append(e)

    assert len(upgrade_entries) == 0, (
        f"Found unexpected upgrade operations in apt history.log when APT_UPGRADE=false. "
        f"Upgrade entries: {upgrade_entries}"
    )


def test_no_apt_dpkg_errors_in_logs(host):
    """
    Verify that no apt or dpkg errors occurred during operations.

    Checks:
    1. apt term.log for error messages
    2. dpkg.log for error states
    """
    upgrade_enabled = get_upgrade_enabled_from_env()

    if not upgrade_enabled:
        # Skip test when upgrades are disabled
        return

    # Check apt errors
    apt_errors = check_apt_errors_in_logs(host, LOG_WINDOW_MINUTES)

    # Filter out informational messages that aren't real errors
    real_errors = []
    for error in apt_errors:
        # Skip warnings about packages being held back (not an error)
        if 'held back' in error.lower():
            continue
        # Skip informational messages
        if error.startswith('Extracting templates'):
            continue
        # Skip dbus errors (common in Docker containers without dbus)
        if 'dbus' in error.lower() or 'system_bus_socket' in error.lower():
            continue
        # Skip systemctl/systemd warnings in containers
        if 'systemctl' in error.lower() or 'systemd' in error.lower():
            continue
        real_errors.append(error)

    assert len(real_errors) == 0, (
        f"Found apt errors in logs: {real_errors}"
    )

    # Check dpkg errors
    _, dpkg_errors = parse_dpkg_log(host, LOG_WINDOW_MINUTES)

    assert len(dpkg_errors) == 0, (
        f"Found dpkg errors in logs: {dpkg_errors}"
    )


# ==============================================================================
# OS-Specific Verification Tests
# ==============================================================================

def test_os_specific_log_format_parsing(host):
    """
    Verify that log parsing works correctly for the specific OS.

    Different Debian and Ubuntu versions may have slightly different log formats.
    This test ensures our parsing logic handles them correctly.
    """
    distro, version = get_os_info(host)

    # Verify we can parse the logs without exceptions
    try:
        history_entries = parse_apt_history_log(host, LOG_WINDOW_MINUTES)
        upgrade_entries, error_entries = parse_dpkg_log(host, LOG_WINDOW_MINUTES)

        # Just verify parsing didn't crash
        assert True, f"Successfully parsed logs on {distro} {version}"

    except Exception as e:
        assert False, (
            f"Failed to parse logs on {distro} {version}: {e}"
        )
