"""Regression checks for builds that accidentally omit OAuth provider flags."""
import importlib.util
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    'configure_services', ROOT / 'scripts/configure_services.py'
)
services = importlib.util.module_from_spec(spec)
spec.loader.exec_module(services)


def configuration():
    return {
        'USE_DEMO_DATA': 'false',
        'SUPABASE_URL': 'https://synthetic-project.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_synthetic_fixture',
        'AUTH_GOOGLE_ENABLED': 'true',
        'AUTH_APPLE_ENABLED': 'false',
        'AUTH_TELEGRAM_ENABLED': 'true',
    }


class ProviderConfigurationTest(unittest.TestCase):
    def test_complete_staging_configuration_is_valid(self):
        self.assertEqual(services.validate(configuration(), 'ios'), [])

    def test_omitted_flags_cannot_silently_disable_sign_in(self):
        for flag in services.FLAGS:
            with self.subTest(flag=flag):
                values = configuration()
                del values[flag]
                self.assertTrue(any(flag in error for error in services.validate(values, 'ios')))

    def test_explicitly_disabled_providers_remain_valid(self):
        values = configuration()
        for flag in services.FLAGS[1:]:
            values[flag] = 'false'
        self.assertEqual(services.validate(values, 'ios'), [])

    def test_boolean_json_values_are_not_valid_dart_defines(self):
        values = configuration()
        values['AUTH_GOOGLE_ENABLED'] = True
        self.assertTrue(services.validate(values, 'ios'))


if __name__ == '__main__':
    unittest.main()
