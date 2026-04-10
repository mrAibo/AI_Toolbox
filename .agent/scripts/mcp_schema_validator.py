#!/usr/bin/env python3
"""mcp_schema_validator.py - Helper for test-mcp-schema.sh
Validates MCP configuration JSON files against expected schemas.

Usage:
  python3 mcp_schema_validator.py <test_name> <json_file>
  
Test names:
  root_key:<key>          - Check root key exists
  server_count:<min>      - Check minimum number of servers
  has_endpoints           - Each server has command/httpUrl/url
  has_args                - Servers with command have args array
  fs_not_dot              - Filesystem server not restricted to '.' only
  no_latest               - No unpinned @latest versions
  opencode_mcp:<min>      - opencode: mcp section with min servers
  opencode_commands       - opencode: has boot/sync/handover commands
  opencode_agents         - opencode: has agents section
  opencode_permission     - opencode: has permission section
  codex_hooks             - .codex-hooks.json: has hooks section
  codex_hooks_required    - .codex-hooks.json: has SessionStart or PreToolUse
  codex_hooks_types       - .codex-hooks.json: each hook has type/command
"""

import json
import re
import sys
import os


def load_json(filepath):
    """Load and parse a JSON file, return dict."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_servers(d, root_key):
    """Get servers dict from config."""
    servers = d.get(root_key, {})
    if not isinstance(servers, dict):
        raise AssertionError(f"'{root_key}' must be a dict, got {type(servers).__name__}")
    return servers


def test_root_key(d, args):
    """Check that root key exists."""
    key = args
    assert key in d, f"Missing root key: '{key}'"


def test_server_count(d, args):
    """Check minimum number of servers."""
    root_key = _detect_root_key(d)
    servers = get_servers(d, root_key)
    min_count = int(args)
    assert len(servers) >= min_count, f"Only {len(servers)} servers, need >= {min_count}"


def test_has_endpoints(d, _args):
    """Each server has command, httpUrl, or url."""
    root_key = _detect_root_key(d)
    servers = get_servers(d, root_key)
    for sname, scfg in servers.items():
        assert isinstance(scfg, dict), f"{sname}: config must be dict"
        has_endpoint = any(k in scfg for k in ('command', 'httpUrl', 'url'))
        assert has_endpoint, f"{sname}: missing command, httpUrl, or url"


def test_has_args(d, _args):
    """Servers with command have args array."""
    root_key = _detect_root_key(d)
    servers = get_servers(d, root_key)
    for sname, scfg in servers.items():
        if 'command' in scfg:
            assert 'args' in scfg, f"{sname}: has command but no args"
            assert isinstance(scfg['args'], list), f"{sname}: args must be a list"


def test_fs_not_dot(d, _args):
    """Filesystem server not restricted to '.' only."""
    root_key = _detect_root_key(d)
    servers = get_servers(d, root_key)
    if 'filesystem' in servers:
        fs = servers['filesystem']
        if 'args' in fs:
            # Filter out npx flags to get path args
            path_args = [a for a in fs['args'] if not a.startswith('-') and a not in ('npx', '-y')]
            if len(path_args) == 1:
                assert path_args[0] != '.', 'filesystem server must not have "." as only path'


def test_no_latest(d, _args):
    """No unpinned @latest versions in args."""
    root_key = _detect_root_key(d)
    servers = get_servers(d, root_key)
    for sname, scfg in servers.items():
        args = scfg.get('args', [])
        for arg in args:
            if arg.startswith('@'):
                assert '@latest' not in arg, f"{sname}: unpinned @latest in {arg}"
                # Check npm package pattern: @scope/name@version or name@version
                if re.match(r'@[\w-]+/[\w-]+$', arg):
                    assert False, f"{sname}: unpinned package {arg} (no @version)"
                elif re.match(r'[\w-]+$', arg) and not arg.startswith('-'):
                    assert False, f"{sname}: unpinned package {arg} (no @version)"


def test_opencode_mcp(d, args):
    """opencode: mcp section with minimum servers."""
    mcp = d.get('mcp', {})
    assert isinstance(mcp, dict), "mcp must be dict"
    min_count = int(args)
    assert len(mcp) >= min_count, f"Only {len(mcp)} MCP servers, need >= {min_count}"


def test_opencode_commands(d, _args):
    """opencode: has boot/sync/handover commands."""
    cmds = d.get('commands', {})
    assert isinstance(cmds, dict), "commands must be dict"
    required = ['boot', 'sync', 'handover']
    for r in required:
        assert r in cmds, f"Missing command: '{r}'"


def test_opencode_agents(d, _args):
    """opencode: has agents section with >= 1 agent."""
    agents = d.get('agents', {})
    assert isinstance(agents, dict), "agents must be dict"
    assert len(agents) >= 1, "No agents defined"


def test_opencode_permission(d, _args):
    """opencode: has permission section with at least one permission."""
    perms = d.get('permission', {})
    assert isinstance(perms, (dict, list)), "permission must be dict or list"
    assert len(perms) >= 1, "No permissions defined"


def test_codex_hooks(d, _args):
    """.codex-hooks.json: has hooks section."""
    hooks = d.get('hooks', {})
    assert isinstance(hooks, dict), "hooks must be dict"
    assert len(hooks) >= 1, "No hooks defined"


def test_codex_hooks_required(d, _args):
    """.codex-hooks.json: has SessionStart or PreToolUse hook."""
    hooks = d.get('hooks', {})
    has_required = any(k in ('SessionStart', 'PreToolUse') for k in hooks)
    assert has_required, f"Missing SessionStart or PreToolUse hook (found: {list(hooks.keys())})"


def test_codex_hooks_types(d, _args):
    """.codex-hooks.json: each hook has type: command and command string."""
    hooks = d.get('hooks', {})
    for hname, hcfg in hooks.items():
        assert isinstance(hcfg, dict), f"{hname}: hook config must be dict"
        assert hcfg.get('type') == 'command', f'{hname}: type must be "command"'
        cmd = hcfg.get('command', '')
        assert isinstance(cmd, str) and len(cmd) > 0, f"{hname}: must have non-empty command string"


def _detect_root_key(d):
    """Detect the root key for servers based on config type."""
    if 'mcpServers' in d:
        return 'mcpServers'
    elif 'mcp' in d:
        return 'mcp'
    elif 'servers' in d:
        return 'servers'
    else:
        raise AssertionError("No recognized root key (mcpServers, mcp, or servers)")


# Registry of test functions
TESTS = {
    'root_key': test_root_key,
    'server_count': test_server_count,
    'has_endpoints': test_has_endpoints,
    'has_args': test_has_args,
    'fs_not_dot': test_fs_not_dot,
    'no_latest': test_no_latest,
    'opencode_mcp': test_opencode_mcp,
    'opencode_commands': test_opencode_commands,
    'opencode_agents': test_opencode_agents,
    'opencode_permission': test_opencode_permission,
    'codex_hooks': test_codex_hooks,
    'codex_hooks_required': test_codex_hooks_required,
    'codex_hooks_types': test_codex_hooks_types,
}


def main():
    if len(sys.argv) < 3:
        print("Usage: mcp_schema_validator.py <test_name[:args]> <json_file>", file=sys.stderr)
        sys.exit(1)

    test_spec = sys.argv[1]
    json_file = sys.argv[2]

    if not os.path.isfile(json_file):
        print(f"FAIL: File not found: {json_file}", file=sys.stderr)
        sys.exit(1)

    # Parse test name and optional args
    if ':' in test_spec:
        test_name, test_args = test_spec.split(':', 1)
    else:
        test_name = test_spec
        test_args = None

    if test_name not in TESTS:
        print(f"FAIL: Unknown test: {test_name}", file=sys.stderr)
        sys.exit(1)

    try:
        d = load_json(json_file)
        TESTS[test_name](d, test_args)
        print("OK")
        sys.exit(0)
    except AssertionError as e:
        print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"FAIL: Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
