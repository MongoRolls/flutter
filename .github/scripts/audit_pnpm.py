"""Fail closed before and after pnpm audit; never install project dependencies."""
import json
from pathlib import Path
import subprocess
import sys

import yaml

TOOLS = {'web': ('8.15.9', '6.0'), 'backend': ('10.28.2', '9.0')}
SECTIONS = ('dependencies', 'devDependencies', 'optionalDependencies')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_lock(manifest, lock, tool, schema):
    require(isinstance(lock, dict), 'Lock must be an object')
    require(str(lock.get('lockfileVersion')) == schema, 'Unsupported lockfile version')
    require(manifest.get('packageManager', 'pnpm@' + tool) == 'pnpm@' + tool,
            'packageManager disagrees with audit tool')
    packages = lock.get('packages')
    require(isinstance(packages, dict) and packages, 'Empty package graph')
    if schema == '9.0':
        importers = lock.get('importers')
        require(isinstance(importers, dict), 'Missing importers')
        root = importers.get('.')
        graph = lock.get('snapshots')
        require(isinstance(graph, dict) and graph, 'Empty snapshot graph')
    else:
        root, graph = lock, packages
    require(isinstance(root, dict), 'Missing root importer')
    count = 0
    for section in SECTIONS:
        expected, resolved = manifest.get(section, {}), root.get(section, {})
        require(isinstance(expected, dict) and isinstance(resolved, dict), 'Invalid dependency section')
        require(set(expected) == set(resolved), 'Manifest/lock dependency names differ')
        for name, specifier in expected.items():
            entry = resolved[name]
            require(isinstance(entry, dict) and entry.get('specifier') == specifier,
                    'Manifest/lock specifier differs: ' + name)
            version = entry.get('version')
            require(isinstance(version, str) and version, 'Missing version: ' + name)
            key = ('/' if schema == '6.0' else '') + name + '@' + version
            require(key in graph, 'Unresolved dependency graph entry: ' + key)
            if schema == '9.0':
                require(name + '@' + version.split('(')[0] in packages,
                        'Missing package metadata: ' + name)
            count += 1
    require(count > 0, 'No root dependencies to audit')
    return count


def validate_report(report, minimum):
    require(isinstance(report, dict) and not report.get('error'), 'Audit returned an error')
    metadata = report.get('metadata')
    require(isinstance(metadata, dict), 'Missing audit metadata')
    total = metadata.get('totalDependencies')
    require(type(total) is int and total >= minimum, 'Empty/incomplete audited dependency tree')
    counts = metadata.get('vulnerabilities')
    require(isinstance(counts, dict), 'Missing vulnerability counts')
    for severity in ('info', 'low', 'moderate', 'high', 'critical'):
        require(type(counts.get(severity)) is int and counts[severity] >= 0,
                'Invalid vulnerability count: ' + severity)
    advisories = report.get('advisories')
    require(isinstance(advisories, dict), 'Missing advisory results')
    # Either signal is sufficient to fail, even if the tool exit code is zero.
    return bool(advisories) or any(counts.values())


def main():
    directory = Path.cwd()
    tool, schema = TOOLS[directory.name]
    actual = subprocess.check_output(['pnpm', '--version'], text=True).strip()
    require(actual == tool, 'Unexpected pnpm version: ' + actual)
    count = validate_lock(json.loads(Path('package.json').read_text()),
                          yaml.safe_load(Path('pnpm-lock.yaml').read_text()), tool, schema)
    result = subprocess.run(['pnpm', 'audit', '--json', '--audit-level=low',
                             '--registry=https://registry.npmjs.org'],
                            text=True, stdout=subprocess.PIPE, check=False)
    print(result.stdout, flush=True)
    affected = validate_report(json.loads(result.stdout), count)
    return result.returncode or int(affected)


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError, subprocess.SubprocessError, yaml.YAMLError) as error:
        sys.exit('Audit could not establish coverage: ' + str(error))
