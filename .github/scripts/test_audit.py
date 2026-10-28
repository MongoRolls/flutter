import copy
import json
from pathlib import Path
import unittest

from audit_pnpm import validate_lock, validate_report
from check_pub_hints import check

FIXTURES = Path(__file__).parent / 'fixtures'


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((FIXTURES / 'pnpm.json').read_text())
        self.pub = json.loads((FIXTURES / 'pub.json').read_text())

    def test_supported_versions(self):
        for key, tool, schema in [('v6', '8.15.9', '6.0'), ('v9', '10.28.2', '9.0')]:
            with self.subTest(key=key):
                self.assertEqual(validate_lock(self.data['manifest'], self.data[key], tool, schema), 1)

    def test_old_lock_with_new_tool_fails(self):
        with self.assertRaises(ValueError):
            validate_lock(self.data['manifest'], self.data['v6'], '10.28.2', '9.0')

    def test_missing_graph_sections_fail(self):
        for section in ('importers', 'packages', 'snapshots'):
            for value in (None, {}, []):
                with self.subTest(section=section, value=value):
                    lock = copy.deepcopy(self.data['v9'])
                    lock[section] = value
                    with self.assertRaises(ValueError):
                        validate_lock(self.data['manifest'], lock, '10.28.2', '9.0')

    def test_unresolved_graph_fails(self):
        self.data['v9']['snapshots'] = {'other@1.0.0': {}}
        with self.assertRaises(ValueError):
            validate_lock(self.data['manifest'], self.data['v9'], '10.28.2', '9.0')

    def test_manifest_drift_fails(self):
        self.data['manifest']['dependencies']['example'] = '^2.0.0'
        with self.assertRaises(ValueError):
            validate_lock(self.data['manifest'], self.data['v6'], '8.15.9', '6.0')

    def test_package_manager_mismatch_fails(self):
        self.data['manifest']['packageManager'] = 'pnpm@10.28.2'
        with self.assertRaises(ValueError):
            validate_lock(self.data['manifest'], self.data['v6'], '8.15.9', '6.0')

    def test_empty_roots_fail(self):
        self.data['v6']['dependencies'] = {}
        with self.assertRaises(ValueError):
            validate_lock({}, self.data['v6'], '8.15.9', '6.0')

    def test_empty_or_unknown_audit_response_fails(self):
        for report in (self.data['emptyTreeReport'], {}, [], {'error': 'unavailable'}):
            with self.subTest(report=report), self.assertRaises(ValueError):
                validate_report(report, 1)

    def test_report_counts_must_be_integers(self):
        for value in (False, None, -1, '0'):
            with self.subTest(value=value):
                report = copy.deepcopy(self.data['cleanReport'])
                report['metadata']['vulnerabilities']['high'] = value
                with self.assertRaises(ValueError):
                    validate_report(report, 1)

    def test_findings_fail_even_with_zero_exit(self):
        report = self.data['cleanReport']
        self.assertFalse(validate_report(report, 1))
        report['metadata']['vulnerabilities']['low'] = 1
        self.assertTrue(validate_report(report, 1))
        report['metadata']['vulnerabilities']['low'] = 0
        report['advisories'] = {'fixture': {}}
        self.assertTrue(validate_report(report, 1))

    def test_pub_hints(self):
        self.assertEqual(check(self.pub), [])
        self.pub['packages'][0]['isCurrentAffectedByAdvisory'] = True
        self.assertEqual(check(self.pub), ['example'])

    def test_pub_unknown_flags_fail(self):
        for value in (None, 0, 1, '', 'false', [], {}):
            with self.subTest(value=value):
                self.pub['packages'][0]['isCurrentAffectedByAdvisory'] = value
                with self.assertRaises(ValueError):
                    check(self.pub)
        del self.pub['packages'][0]['isCurrentAffectedByAdvisory']
        with self.assertRaises(ValueError):
            check(self.pub)

    def test_pub_unknown_shape_fails(self):
        for data in ({}, [], {'packages': []}, {'packages': [False]}, {'error': 'unavailable'}):
            with self.subTest(data=data), self.assertRaises(ValueError):
                check(data)

    def test_pub_missing_current_and_duplicates_fail(self):
        duplicate = copy.deepcopy(self.pub)
        duplicate['packages'] *= 2
        with self.assertRaises(ValueError):
            check(duplicate)
        del self.pub['packages'][0]['current']
        with self.assertRaises(ValueError):
            check(self.pub)


if __name__ == '__main__':
    unittest.main()
