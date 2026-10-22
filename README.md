# AI-Assisted FMCG Sales Forecasting & Business Reporting

A personal retail analytics portfolio project connecting Python, Snowflake, SQL and Power BI to analyse sales, forecast units sold and prioritise unusual sales records for investigation.

The AI reporting extension uses an LLM API to draft weekly briefings from structured evidence, with automated checks, guided review and retained revision records.

## Explore the project

- [Example weekly sales review](reports/examples/weekly_sales_review_20160522.md)
- [Validation and evaluation](docs/evaluation.md)
- [Running instructions](docs/running.md)

The example is a historical demonstration and remains a draft pending human approval.

## Business questions

- Which stores and departments contribute most to revenue?
- How do sales vary by weekday and month?
- What unit sales does the model forecast over the next 28 days?
- Which store-department-day records warrant investigation?
- How can AI assist with reporting while keeping figures traceable?

The outputs support planning and analytical investigation. They do not prescribe inventory orders or establish the causes of unusual sales.

## Data and tools

**Source:** Walmart M5 competition dataset, obtained through Kaggle.

The selected scope contains approximately **10.49 million item-store-day records**, covering **10 stores** across California, Texas and Wisconsin and **three food departments**: FOODS_1, FOODS_2 and FOODS_3.

The historical period is **24 May 2014–22 May 2016**. The first and last months are partial months. Monetary values are in **USD**. The aggregated daily sales table contains 21,900 date-store-department records.

| Input | Use |
| --- | --- |
| `sales_train_evaluation.csv` | Historical daily unit sales |
| `calendar.csv` | Dates, weekdays, events and state-specific SNAP indicators |
| `sell_prices.csv` | Item-store-week prices used to calculate revenue |

| Technology | Role |
| --- | --- |
| Python, pandas, NumPy | Data preparation, KPI calculations and reporting tables |
| scikit-learn | Forecast adjustment modelling |
| Snowflake and SQL | Data organisation and reporting preparation |
| Power BI, Power Query and DAX | Interactive sales and forecast reporting |
| OpenAI API | Evidence-based narrative drafting |
| Jupyter Notebook | Analysis and reporting development |
| Python unittest | Independent validation tests |

Snowflake organises the data into raw, stage and analytics schemas. Python prepares forecasting and reporting outputs for analysis in Power BI.

## Dashboard

[View the Power BI Dashboard (PDF)](FMCG_Sales_Dashboard.pdf)

| Page | Purpose |
| --- | --- |
| FMCG Sales Overview | Revenue, units, revenue per unit, store rankings and department contribution |
| FMCG Sales Patterns | Weekday demand, complete-month revenue growth and department mix by store |
| Forecast & Alerts | Future unit sales, historical actual versus expected sales, WAPE, bias and alert drill-down |
| AI-Assisted Sales Review | Evidence-based findings, proposed investigations and limitations |

The PBIX supports interactive filtering. PDF exports provide static previews and may show only the visible portion of scrolling tables.

## Workflow

1. Inspect source files, date coverage, keys and missing values.
2. Prepare sales and calendar data and calculate revenue using corresponding prices.
3. Load and organise reporting data in Snowflake.
4. Explore sales patterns in Power BI.
5. Compare forecasting approaches across historical windows.
6. Export future forecasts and historical review records.
7. Apply business alert rules.
8. Prepare a structured evidence package for weekly reporting.
9. Generate an AI narrative and review it against the evidence.
10. Save revisions, validation records and a manager-facing Markdown report.

## Forecasting approach

The selected model is a **four-week weekday average with a Ridge regression adjustment**.

- The baseline uses the preceding four observations for the same weekday, store and department.
- The baseline remains fixed throughout each 28-day forecast horizon.
- Ridge regression learns relative adjustments from event types, state-specific SNAP flags and categorical interactions.
- Monthly interactions vary by state, department and month phase: days 1–7, 8–15, 16–22 and 23–month end.
- Predictions are constrained to be non-negative.

For historical fitting, baselines use past observations and models are fitted using records preceding their forecast windows. The future model is refitted using observed history through 22 May 2016.

### Historical comparison

Each window covers 28 days. WAPE is calculated across individual store-department-day records.

| Forecast start | Calendar-adjusted WAPE | Calendar + monthly patterns WAPE |
| --- | ---: | ---: |
| 4 Jan 2016 | 18.66% | 18.76% |
| 1 Feb 2016 | 13.04% | 12.99% |
| 29 Feb 2016 | 11.10% | 10.76% |
| 28 Mar 2016 | 9.25% | 8.46% |

Monthly features improved three of four windows, with a small deterioration in January.

### Final historical review: 25 Apr–22 May 2016

| Model | WAPE | Bias |
| --- | ---: | ---: |
| Four-week weekday average | 12.52% | -4.99% |
| Calendar-adjusted average | 10.96% | -3.30% |
| Calendar + monthly patterns | 10.38% | -3.13% |

**Evaluation caveat:** Monthly features were proposed after inspecting the final historical period. Although fitting used preceding observations, feature selection was informed by that period. The upgraded results and backtests are exploratory, not an untouched holdout estimate. Evaluation on unseen periods is still needed.

### Metrics and forecast scope

- **WAPE:** sum of absolute prediction errors divided by total actual units.
- **Bias:** total predicted units minus total actual units, divided by total actual units. Negative bias indicates overall underprediction.

The future forecast covers **23 May–19 June 2016**, with **840 records**: 28 days × 10 stores × 3 departments. These forecasts extend beyond the observed project history; they are not forecasts for the present day.

## Alert rules and findings

A record triggers an alert only when **both** conditions hold:

| Rule | Threshold |
| --- | ---: |
| Absolute deviation from expected sales | At least 25% |
| Absolute unit difference | At least 100 units |

Relative deviation is `(actual - expected) / expected`. The exported `deviation_pct` field expresses this as a percentage: `25` means 25%.

These thresholds are illustrative business rules, not statistically calibrated prediction intervals.

The final historical review contains **92 alerts out of 840 records (10.95%)**:

- 80 above expected and 12 below expected.
- Foods 1 accounts for 70 alerts, all above expected, motivating an underprediction review.
- Wisconsin stores account for 42 alerts; WI 2 has 17 and WI 3 has 15.
- WI 2 / Foods 2 is below expected on 20–22 May, with deviations of approximately -31.4%, -35.6% and -30.1%.

Earlier monthly comparisons showed recurring declines in Wisconsin Foods 2. This motivated calendar interactions but does not establish SNAP, stockouts or external events as causes. Operational evidence would be needed to investigate those explanations.

## AI-assisted weekly reporting

The reporting extension uses an LLM API to draft a briefing from a structured evidence package. **Python calculates the metrics and renders the tables.** Narrative statements retain evidence IDs in the JSON draft; the manager-facing report uses readable labels.

The example reviews **16–22 May 2016** against **9–15 May 2016**.

| Report section | Contents |
| --- | --- |
| Executive summary | Overall results and a selected store observation |
| Overall performance | Previous and current revenue and units, with changes |
| Department performance | Revenue comparisons across all three food departments |
| Store highlights | Selected store-department revenue breakdowns |
| Historical alerts | Weekly counts, selected records and exploratory observations |
| Next-week forecast | Forecast units for 23–29 May 2016 by department |
| Proposed actions | Specific investigations and expected outputs |
| Notes | Historical scope, uncertainty and pending approval |

### Evidence, revisions and a real AI error

Original AI drafts, evidence packages, guided revisions and validation records are retained.

Guided review found that the AI described observations of **815, 850 and 836 units** as a range of **815–836**. The range was corrected to **815–850**. A targeted validator was subsequently added to reject the original error and accept the correction.

The AI also proposed investigating inventory and staffing data that were not supplied. The action was revised to use available daily sales data.

The workflow is notebook-based and includes manual review and revision. It is not scheduled or deployed. The example remains a draft with human approval pending; an approval interface and automated publication controls have not been implemented.

## Validation and testing

| Check | Coverage |
| --- | --- |
| Report metadata | Report ID and report/comparison periods match the evidence |
| Structure | Draft status, section counts and required text fields |
| Evidence references | ID existence and duplicate IDs in the evidence package |
| Actual-unit ranges | Supported wording compared with cited alert records |
| Guided content review | Figures, dates, directions of change, units and forecast wording |
| Four-week data checks | Record coverage, actual-unit reconciliation and alert calculations |

The independent unittest suite passed **three test methods**, containing five structure scenarios, five range scenarios and two real-error regression checks. Unsupported range wording returns `REVIEW` for manual assessment.

Four historical weeks were checked across **840 records**:

| Week ending | Reviewed records | Alerts | Above expected | Below expected |
| --- | ---: | ---: | ---: | ---: |
| 1 May 2016 | 210 | 20 | 19 | 1 |
| 8 May 2016 | 210 | 38 | 30 | 8 |
| 15 May 2016 | 210 | 16 | 16 | 0 |
| 22 May 2016 | 210 | 18 | 15 | 3 |
| **Total** | **840** | **92** | **80** | **12** |

These checks establish data alignment and rule consistency. They do **not** measure overall LLM accuracy, model accuracy or business-issue detection accuracy. Four weeks of LLM-generated reports have not been benchmarked.

See [evaluation details](docs/evaluation.md) for the test scope and limitations.

## Files and reproduction

| Location | Contents |
| --- | --- |
| `data/raw/m5/` | M5 source CSV files |
| `data/processed/` | Prepared sales, forecasting and historical review tables |
| `sql/` | SQL preparation and reporting files |
| `notebooks/01_data_inspection.ipynb` | Initial data inspection |
| `notebooks/02_sales_forecasting.ipynb` | Forecasting, evaluation and alert preparation |
| `notebooks/03_ai_business_reporting.ipynb` | AI reporting development and guided review |
| `prompts/weekly_sales_review_v2.txt` | Reporting instructions |
| `src/report_validation.py` | Reusable validation functions |
| `tests/` | Independent tests and bundled JSON fixtures |
| `reports/evidence/` | Structured evidence packages |
| `reports/drafts/` | Original and revised drafts |
| `reports/examples/` | Selected demonstration report |
| `reports/validation/` | Validation records and test summaries |
| `docs/` | Evaluation and running instructions |

Key processed outputs include:

- `daily_store_dept_sales.csv`
- `future_sales_forecast_monthly_patterns.csv`
- `sales_anomaly_review_monthly_patterns.csv`
- `forecast_monthly_pattern_backtests.csv`
- `forecast_monthly_pattern_test_metrics.csv`
- `forecast_monthly_pattern_test_predictions.csv`
- `foods2_monthly_state_pattern_review.csv`
- `dashboard_alerts_export.csv`

### View the example or run tests

The [saved report](reports/examples/weekly_sales_review_20160522.md) can be read without an API key or database connection.

From the project root, run:

```bash
python -m unittest discover -s tests -p "test_report_validation.py" -v
```

These tests use Python's standard library and bundled fixtures. They do not require pandas, Snowflake or a paid API call.

### Reproduce the analysis

1. Obtain the M5 source files and place them in `data/raw/m5/`.
2. Update notebook paths for your machine.
3. Run the data inspection and forecasting notebooks in order.
4. Configure Snowflake and run the SQL preparation workflow.
5. Update the Power BI source settings and refresh the report.
6. Follow [the reporting instructions](docs/running.md) before executing the reporting notebook.

The reporting notebook contains development and revision cells. A clean end-to-end rerun has not yet been verified. API generation cells make paid requests; do not automatically execute every cell.

Source data, credentials and machine-specific connection settings must be obtained or configured separately. Availability of local data files in a published checkout must be checked separately. Keep API keys out of source code, notebook output and committed configuration files.

The demonstrated workflow used **Python 3.9.15**. Validation tests passed in an independent Python process. A fresh-environment installation has not yet been verified.

## Limitations and next steps

- The dataset represents US Walmart food sales, not New Zealand retail demand.
- Observed sales do not necessarily equal unconstrained demand.
- Inventory, stockout and promotion execution data are unavailable for causal investigation.
- Historical model selection and backtests are exploratory; unseen-period evaluation is needed.
- Aggregate metrics can conceal local errors, and alert counts depend on the thresholds.
- Valid evidence IDs do not guarantee that narrative claims are supported.
- Range validation supports limited wording and checks only referenced records, not complete date coverage.
- Other numerical claims, rankings, causal statements and action feasibility require separate checks or review.
- The reporting extension has not independently audited model training and tuning leakage.
- Business time savings and ROI have not been measured.

Next steps are to verify a clean reporting run, benchmark additional AI reports, extend content validation, evaluate unseen forecasting periods and measure reporting effort using explicit assumptions.

## Author

Jiali Yang
