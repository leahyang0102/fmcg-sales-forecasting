# Reporting Validation and Evaluation

## Scope

This personal portfolio project combines historical sales metrics,
exploratory model-based alerts, forecasts and AI-assisted narrative.

Tables are generated programmatically. AI-generated narrative is
reviewed against evidence and revised where needed.

## Automated Checks

The validation module checks:

- Report ID and report/comparison periods.
- Draft status, section counts and required text fields.
- Evidence ID existence and duplicate IDs in the evidence package.
- Supported actual-unit range phrases against cited alert records.

Unsupported range wording returns REVIEW for manual assessment.
A passing range check does not validate the entire statement.

## Test Results

Three unittest methods passed, covering:

- Five structure scenarios.
- Five actual-unit range scenarios.
- Two regression checks comparing the original AI error and correction.

Run this command from the project root:

    python -m unittest discover -s tests -p "test_report_validation.py" -v

These tests assess validator behavior, not overall LLM accuracy.

## Real AI Error

For WI 2 / Foods 2 on 20-22 May 2016, actual sales were
815, 850 and 836 units.

The original AI draft incorrectly reported a range of 815-836 units.
Guided evidence review corrected it to 815-850 units.

A targeted range validator was added after the error was found.
Its regression test rejects the original range and accepts the correction.

The AI also proposed using inventory and staffing data that were not
supplied. The action was revised to use available daily sales data.

## Four-Week Data Validation

Period: 25 April-22 May 2016.

- Four weeks, each containing 210 daily store-department records.
- 840 reviewed records and 92 alerts.
- Weekly alert counts: 20, 38, 16 and 18.
- Actual units reconciled to the processed sales source.
- Deviations, alert flags and classifications matched recalculated values.
- Alerts require both absolute deviation of at least 25% and
  an absolute difference of at least 100 units.

This validates data alignment and rule calculations. It does not
evaluate four weeks of LLM reports or establish model accuracy.

## Review and Approval

Guided review compared narrative figures, dates, directions of change,
units and forecast wording with cited evidence.

Original drafts and revision records are retained.
The example report remains a draft with human approval pending.

Approval status is recorded. An approval interface and automated
publication controls have not been implemented.

## Limitations

- Valid evidence IDs do not guarantee supported claims.
- Range checks support limited wording and only the referenced records.
- Complete date coverage is not verified by the range checker.
- Other numerical claims, rankings, causal statements and action
  feasibility require separate checks or manual review.
- Historical alerts are exploratory.
- Model training and tuning leakage have not been audited here.
- Forecasts estimate units sold, not revenue or guaranteed demand.
- No representative multi-report LLM benchmark has been completed.
- Business time savings and ROI have not yet been measured.

## Supporting Files

- [Example report](../reports/examples/weekly_sales_review_20160522.md)
- [Validation module](../src/report_validation.py)
- [Tests](../tests/test_report_validation.py)
- [Validator results](../reports/validation/weekly_sales_20160522_evaluation_tests_v1.json)
- [Four-week summary](../reports/validation/four_week_validation_summary.csv)
- [Four-week record](../reports/validation/four_week_validation_record.json)
