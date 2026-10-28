"""Check SDK advisory hints, not a complete Pub vulnerability scan."""
import json
import sys

import yaml


def check(data, locked=None, sdk=()):
    if not isinstance(data, dict) or data.get('error'):
        raise ValueError('Pub returned an error or invalid response')
    packages = data.get('packages')
    if not isinstance(packages, list) or not packages:
        raise ValueError('Pub returned no package advisory hints')
    affected, seen = [], set()
    for package in packages:
        if not isinstance(package, dict):
            raise ValueError('Invalid Pub package')
        name = package.get('package')
        if not isinstance(name, str) or not name or name in seen:
            raise ValueError('Invalid/duplicate Pub package name')
        seen.add(name)
        if name in sdk:
            continue  # Flutter/Dart SDK components are not Pub-hosted packages.
        flag = package.get('isCurrentAffectedByAdvisory')
        if type(flag) is not bool:
            raise ValueError('Missing/non-boolean advisory hint: ' + name)
        current = package.get('current')
        if locked is not None and name not in locked and current is None:
            # Outdated also includes packages introduced only by newer resolutions.
            continue
        if not isinstance(current, dict) or not isinstance(current.get('version'), str) or not current['version']:
            raise ValueError('Missing installed version: ' + name)
        if locked is not None and (name not in locked or current['version'] != locked[name]):
            raise ValueError('Pub hint does not match locked version: ' + name)
        if flag:
            affected.append(name)
    if locked is not None and (not locked or not set(locked).issubset(seen)):
        raise ValueError('Pub omitted locked package advisory hints')
    return affected


if __name__ == '__main__':
    try:
        with open(sys.argv[1]) as source:
            lock = yaml.safe_load(source)
        locked = {name: str(package['version']) for name, package in lock['packages'].items()
                  if package['source'] != 'sdk'}
        sdk = {name for name, package in lock['packages'].items() if package['source'] == 'sdk'}
        affected = check(json.load(sys.stdin), locked, sdk)
        print('Packages flagged by Pub SDK advisory hints:', affected)
        print('Coverage is limited to SDK hints; false does not establish upstream advisory availability or absence of vulnerabilities.')
        sys.exit(bool(affected))
    except (ValueError, TypeError, KeyError, IndexError, OSError, yaml.YAMLError) as error:
        sys.exit('Pub hint check failed: ' + str(error))
