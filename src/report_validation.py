"""Validate report structure and supported actual-unit ranges."""

import math
import re

def validate_report_structure(report, evidence):
    errors = []
    evidence_ids = []

    def collect_ids(value):
        if isinstance(value, dict):
            if "evidence_id" in value:
                evidence_ids.append(value["evidence_id"])
            for child in value.values():
                collect_ids(child)
        elif isinstance(value, list):
            for child in value:
                collect_ids(child)

    collect_ids(evidence)

    if not all(isinstance(item, str) for item in evidence_ids):
        return ["Evidence package contains invalid evidence IDs."]

    if len(evidence_ids) != len(set(evidence_ids)):
        errors.append("Evidence package contains duplicate evidence IDs.")

    valid_ids = set(evidence_ids)

    if not isinstance(report, dict):
        return errors + ["Report must be a JSON object."]

    for field in ["report_id", "report_period", "comparison_period"]:
        if field not in report or report[field] != evidence.get(field):
            errors.append(f"{field}: missing or does not match evidence.")

    if report.get("status") != "draft":
        errors.append("status: must be draft.")

    section_rules = {
        "executive_summary": (2, 2, ["text"]),
        "alert_commentary": (1, 2, ["text"]),
        "forecast_commentary": (1, 1, ["text"]),
        "proposed_actions": (2, 2, ["action", "expected_output"]),
    }

    for section, (minimum, maximum, text_fields) in section_rules.items():
        items = report.get(section)

        if not isinstance(items, list):
            errors.append(f"{section}: must be a list.")
            continue

        if not minimum <= len(items) <= maximum:
            errors.append(f"{section}: incorrect item count.")

        for position, item in enumerate(items, start=1):
            label = f"{section}[{position}]"

            if not isinstance(item, dict):
                errors.append(f"{label}: must be an object.")
                continue

            for field in text_fields:
                value = item.get(field)
                if not isinstance(value, str) or not value.strip():
                    errors.append(f"{label}.{field}: missing or empty.")

            references = item.get("evidence_ids")

            if (
                not isinstance(references, list)
                or not references
                or not all(isinstance(ref, str) for ref in references)
            ):
                errors.append(f"{label}: invalid evidence_ids.")
                continue

            for reference in references:
                if reference not in valid_ids:
                    errors.append(
                        f"{label}: unknown evidence ID {reference}."
                    )

    limitations = report.get("limitations")

    if (
        not isinstance(limitations, list)
        or not limitations
        or not all(
            isinstance(item, str) and item.strip()
            for item in limitations
        )
    ):
        errors.append("limitations: must be a non-empty list of text.")

    return errors


def validate_actual_unit_range(item, evidence):
    pattern = (
        r"actual\s+(?:sales|units)\s+"
        r"(?:ranged\s+from|between)\s+"
        r"([\d,]+(?:\.\d+)?)\s+"
        r"(?:to|and)\s+"
        r"([\d,]+(?:\.\d+)?)"
    )

    match = re.search(pattern, item["text"], flags=re.IGNORECASE)

    if match is None:
        return {
            "result": "REVIEW",
            "reason": "No supported actual-unit range phrase found.",
        }

    lookup = {
        row["evidence_id"]: row
        for row in evidence["model_evidence"]["alert_records"]
    }

    references = item["evidence_ids"]

    if not references or any(ref not in lookup for ref in references):
        return {
            "result": "REVIEW",
            "reason": "References must identify alert records.",
        }

    records = [lookup[ref] for ref in references]

    groups = {
        (row["store_id"], row["department_id"])
        for row in records
    }

    if len(groups) != 1:
        return {
            "result": "REVIEW",
            "reason": "Referenced records cover multiple store-department groups.",
        }

    reported = [
        float(value.replace(",", ""))
        for value in match.groups()
    ]

    actual_values = [row["actual_units"] for row in records]
    expected = [min(actual_values), max(actual_values)]

    matched = all(
        math.isclose(found, correct, rel_tol=0, abs_tol=0.000001)
        for found, correct in zip(reported, expected)
    )

    return {
        "result": "PASS" if matched else "FAIL",
        "reported_range": reported,
        "evidence_range": expected,
    }
