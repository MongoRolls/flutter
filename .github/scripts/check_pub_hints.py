"""Check SDK advisory hints, not a complete Pub vulnerability scan."""
import json
import sys


def check(data):
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
        flag = package.get('isCurrentAffectedByAdvisory')
        if type(flag) is not bool:
            raise ValueError('Missing/non-boolean advisory hint: ' + name)
        current = package.get('current')
        if not isinstance(current, dict) or not isinstance(current.get('version'), str) or not current['version']:
            raise ValueError('Missing installed version: ' + name)
        if flag:
            affected.append(name)
    return affected


if __name__ == '__main__':
    try:
        affected = check(json.load(sys.stdin))
        print('Packages flagged by Pub SDK advisory hints:', affected)
        print('Coverage is limited to SDK hints; false does not establish upstream advisory availability or absence of vulnerabilities.')
        sys.exit(bool(affected))
    except (ValueError, TypeError) as error:
        sys.exit('Pub hint check failed: ' + str(error))
