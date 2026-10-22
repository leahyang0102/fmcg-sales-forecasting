# Running the AI Reporting Extension

## Existing Example

Open the example report without an API key or database connection:

- [Weekly sales review](../reports/examples/weekly_sales_review_20160522.md)
- [Validation and evaluation](evaluation.md)

The example remains a draft pending human approval.

## Run Validation Tests

From the project root, run:

    python -m unittest discover -s tests -p "test_report_validation.py" -v

The tests use Python's standard library and bundled JSON fixtures.
They do not require pandas, Snowflake, an API key or a paid API call.

Expected result: three test methods pass.
The methods contain multiple structure, range and regression scenarios.

## Notebook Workflow

The notebooks are:

1. notebooks/01_data_inspection.ipynb
2. notebooks/02_sales_forecasting.ipynb
3. notebooks/03_ai_business_reporting.ipynb

The reporting extension reuses these processed files:

- data/processed/daily_store_dept_sales.csv
- data/processed/future_sales_forecast_monthly_patterns.csv
- data/processed/sales_anomaly_review_monthly_patterns.csv

These files are present in the development folder. Availability in a
published repository must be checked separately.

The reporting notebook calculates KPIs, prepares evidence, calls the
LLM API, supports guided review and renders a Markdown report.

The notebook currently contains development and revision cells.
A clean end-to-end rerun has not yet been verified. Do not run every
cell automatically: API generation cells make paid requests, and some
revision cells refer to particular saved drafts.

## Configuration

Set the project root in the notebook to the local checkout folder.
The development path was D:/ai-fmcg-sales-insights.

API generation requires an API key supplied through the environment
or a hidden input prompt. Do not place the key in source code,
notebook output or committed configuration files.

Viewing the saved example and running the validation tests do not
require an API key.

## Outputs

- reports/evidence/: evidence packages.
- reports/drafts/: generated drafts and revised previews.
- reports/examples/: selected demonstration report.
- reports/validation/: validation records and test summaries.

Original AI drafts are retained alongside revisions for traceability.

## Verified Environment

The demonstrated workflow ran in Python 3.9.15.
Validation tests passed in an independent Python process.
Installation and execution in a fresh environment have not yet
been verified.
