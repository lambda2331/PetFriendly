"""Guard the source-preserving English build transformation."""
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tooling/portfolio'))
from dart_strings import segments
spec = importlib.util.spec_from_file_location('web_demo_build', ROOT/'scripts/build-web-demo.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class LocalizationTests(unittest.TestCase):
    def test_nested_interpolation_preserves_expressions(self):
        source = "Text('Привет ${rows.where((r) => r['name'] == 'Имя').first['name']}!')"
        result = build.translate(source, {'Привет ': 'Hello ', 'Имя': 'Name'}, set(), 'fixture.dart')
        self.assertEqual(result, "Text('Hello ${rows.where((r) => r['name'] == 'Name').first['name']}!')")

    def test_comments_do_not_become_display_strings(self):
        source = "// 'не переводить'\n/* nested /* 'не переводить' */ */ Text('Привет')"
        self.assertEqual([value for _,_,value,_ in segments(source)], ['Привет'])

    def test_new_copy_fails_closed(self):
        with self.assertRaisesRegex(ValueError, 'Missing English translation'):
            build.translate("Text('Новая строка')", {}, set(), 'fixture.dart')

    def test_quotes_and_dollars_stay_literal(self):
        result = build.translate("Text('Цена')", {'Цена': "A person's $5\nquote"}, set(), 'fixture.dart')
        self.assertEqual(result, "Text('A person\\'s \\$5\\nquote')")

    def test_canonical_app_has_complete_catalog(self):
        output, manifest = build.prepare()
        self.assertGreater(manifest['english_entries'], 800)
        self.assertEqual(manifest['map'], 'offline-mock')
        self.assertIn('PORTFOLIO_DEMO', (output/'lib/core/backend/backend.dart').read_text())


if __name__ == '__main__':
    unittest.main()
