import json
import sys
import unittest
from copy import deepcopy
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from report_validation import (
    validate_report_structure,
    validate_actual_unit_range,
)


class ReportValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fixture_path = (
            Path(__file__).parent
            / "fixtures"
            / "report_validation_cases.json"
        )
        cls.data = json.loads(
            fixture_path.read_text(encoding="utf-8")
        )

    def test_structure_cases(self):
        for case in self.data["structure_cases"]:
            with self.subTest(case=case["name"]):
                errors = validate_report_structure(
                    case["report"], self.data["evidence"]
                )
                if case["expected_error"] is None:
                    self.assertEqual(errors, [])
                else:
                    self.assertTrue(any(
                        case["expected_error"] in error
                        for error in errors
                    ))

    def test_actual_unit_ranges(self):
        cases = [
            ("Actual sales ranged from 815 to 850 units.", "PASS"),
            ("Actual sales ranged from 800 to 850 units.", "FAIL"),
            ("Actual sales ranged from 815 to 836 units.", "FAIL"),
            ("Actual sales ranged from 850 to 815 units.", "FAIL"),
            ("Actual sales varied across the three dates.", "REVIEW"),
        ]
        for text, expected in cases:
            with self.subTest(text=text):
                item = deepcopy(self.data["range_item"])
                item["text"] = text
                result = validate_actual_unit_range(
                    item, self.data["evidence"]
                )
                self.assertEqual(result["result"], expected)

    def test_real_ai_error_regression(self):
        for field, expected in [
            ("original_range_item", "FAIL"),
            ("range_item", "PASS"),
        ]:
            with self.subTest(draft=field):
                result = validate_actual_unit_range(
                    self.data[field], self.data["evidence"]
                )
                self.assertEqual(result["result"], expected)


if __name__ == "__main__":
    unittest.main()
