# AI-Assisted FMCG Sales Forecasting & Decision Support

A retail analytics portfolio project that connects Python, Snowflake and Power BI to explain sales patterns, forecast demand and prioritise unusual sales records for investigation.

The project uses the food departments of the Walmart M5 dataset. It combines an interpretable forecasting model with business alert rules and an AI-assisted, manually checked sales review.

## Business questions

- Which stores and departments contribute most to sales revenue?
- How do sales vary by weekday and month?
- What demand should stores expect over the next 28 days?
- Which store-department-day records differ enough from expectations to warrant investigation?

The outputs support demand planning and analytical triage. They do not prescribe inventory orders or establish the causes of unusual sales.

## Dashboard

The Power BI report contains four pages:

| Page | Purpose |
| --- | --- |
| FMCG Sales Overview | Revenue, units, revenue per unit, store rankings and department contribution |
| FMCG Sales Patterns | Weekday demand, complete-month revenue growth and department mix by store |
| Forecast & Alerts | Future demand, historical actual versus expected sales, WAPE, bias and alert drill-down |
| AI-Assisted Sales Review | Evidence-based findings, recommended investigations and limitations |

The historical reporting scope covers 10 stores across California, Texas and Wisconsin, and three food departments: FOODS_1, FOODS_2 and FOODS_3. The reported period is 23 May 2014 to 22 May 2016; the first and last months are partial months. Revenue is in USD.

To include the dashboard in this repository, save the final PDF as `reports/fmcg_sales_dashboard.pdf`. The PDF provides a static preview; the PBIX preserves interactive filtering.

## Data and tools

**Source:** Walmart M5 competition dataset, obtained through Kaggle.

| Input | Use |
| --- | --- |
| sales_train_evaluation.csv | Historical daily unit sales |
| calendar.csv | Dates, weekdays, events and state-specific SNAP indicators |
| sell_prices.csv | Item-store-week prices for revenue calculations |

**Tools:** Python, pandas, NumPy, scikit-learn, Jupyter Notebook, Snowflake, SQL, Power BI, Power Query and DAX.

Snowflake organises the data into raw, stage and analytics schemas. Python prepares and evaluates forecasts, then exports reporting tables. Power BI combines sales reporting with these prediction and review outputs.

## Workflow

1. Inspect source files, date coverage, keys and missing values.
2. Prepare sales and calendar data and calculate sales revenue from units and corresponding prices.
3. Load and organise the reporting data in Snowflake.
4. Explore revenue, weekday patterns and store-department differences in Power BI.
5. Compare forecasting approaches using chronological validation and rolling forecast windows.
6. Investigate prediction deviations and develop state-department monthly pattern features.
7. Export the selected model's future forecasts and historical review records.
8. Build business alerts and produce an AI-assisted narrative checked against the exported data.

## Forecasting approach

The selected model is a **four-week weekday average with a Ridge regression adjustment**.

- The baseline uses the preceding four observations for the same weekday, store and department.
- The baseline remains fixed throughout each 28-day forecast horizon.
- Ridge regression learns relative adjustments from event types, state-specific SNAP flags and categorical interactions.
- Monthly interactions allow associations to vary by state, department and month phase: days 1-7, 8-15, 16-22 and 23-month end.
- Predictions are constrained to be non-negative.

For historical fitting, baseline values use past observations only. Each evaluation model is fitted using records dated before its forecast window. The model for the future forecast is refitted using all observed history through 22 May 2016.

### Historical comparison

Each window covers 28 days. WAPE is calculated across individual store-department-day records, rather than after aggregating away their errors.

| Forecast start | Calendar-adjusted WAPE | Calendar + monthly patterns WAPE |
| --- | ---: | ---: |
| 4 Jan 2016 | 18.66% | 18.76% |
| 1 Feb 2016 | 13.04% | 12.99% |
| 29 Feb 2016 | 11.10% | 10.76% |
| 28 Mar 2016 | 9.25% | 8.46% |

Monthly features improved three of four historical windows, with a small deterioration in January.

### Final historical period: 25 Apr-22 May 2016

| Model | WAPE | Bias |
| --- | ---: | ---: |
| Four-week weekday average | 12.52% | -4.99% |
| Calendar-adjusted average | 10.96% | -3.30% |
| Calendar + monthly patterns | 10.38% | -3.13% |

**Evaluation caveat:** Monthly pattern features were proposed after inspecting the final historical period. Although each model was trained only on preceding observations, feature selection was informed by that period. The upgraded results and historical backtests are therefore exploratory, not an untouched holdout estimate. Further evaluation on unseen periods is needed.

### Metrics

- **WAPE:** sum of absolute prediction errors divided by total actual units.
- **Bias:** total predicted units minus total actual units, divided by total actual units.
- Negative bias indicates overall underprediction; positive bias indicates overprediction.

The future forecast covers **23 May-19 Jun 2016**, with 840 records: 28 days × 10 stores × 3 departments. These are forecasts beyond the observed history used in this project, not forecasts for the present day.

## Alert rules and findings

A record triggers an alert only when both conditions are met:

- Absolute deviation from expected sales is at least 25%.
- Absolute unit difference is at least 100 units.

Deviation is defined as `(actual - expected) / expected`. These thresholds are illustrative business rules, not statistically calibrated prediction intervals.

The final historical review contains **92 alerts out of 840 records (10.95%)**:

- 80 above expected and 12 below expected.
- FOODS_1 contributes 70 alerts, all above expected, motivating a department-level underprediction review.
- Wisconsin stores contribute 42 alerts; WI_2 has 17 and WI_3 has 15.
- WI_2 FOODS_2 is below expected on 20-22 May, with deviations of -31.4%, -35.6% and -30.1%.

Earlier monthly comparisons showed recurring declines in Wisconsin FOODS_2. This motivated calendar interactions, but does not establish SNAP, stockouts or external events as causes. Operational data would be needed to investigate those explanations.

## Role of AI

AI assisted with drafting the narrative from exported alert records. Counts and specific examples were checked against the data, and the final text separates observations from possible explanations.

The summary is a **static, manually reviewed output**. This project does not currently implement an automated LLM pipeline, live dashboard commentary or an autonomous decision system.

## Files and reproduction

The local project uses the following locations:

| Location | Contents |
| --- | --- |
| data/raw/m5/ | The three source CSV files |
| data/processed/ | Prepared reporting, forecast and evaluation CSV files |
| notebooks/01_data_inspection.ipynb | Initial data inspection |
| notebooks/02_sales_forecasting.ipynb | Forecasting, evaluation and alert preparation |
| reports/ | Dashboard PDF exports |

Key outputs include:

- `future_sales_forecast_monthly_patterns.csv`
- `sales_anomaly_review_monthly_patterns.csv`
- `forecast_monthly_pattern_backtests.csv`
- `forecast_monthly_pattern_test_metrics.csv`
- `forecast_monthly_pattern_test_predictions.csv`
- `foods2_monthly_state_pattern_review.csv`
- `dashboard_alerts_export.csv`

To reproduce the analysis:

1. Obtain the M5 source files and place them in `data/raw/m5/`.
2. Update notebook input and output paths for your machine.
3. Run the notebooks in order. A restarted Jupyter kernel requires rerunning earlier cells to restore variables.
4. Configure the Snowflake connection and run the project's SQL preparation workflow.
5. Open the Power BI report, update Snowflake and CSV source settings, then refresh.
6. Check the historical review has 840 records, 92 alerts, approximately 10.38% WAPE and -3.13% bias without filters.

Source data, credentials and machine-specific connection settings must be obtained or configured separately. The dashboard PDF alone cannot reproduce the analysis.

## Limitations and next steps

- The project analyses US Walmart food sales; it is not evidence of New Zealand retail demand.
- Observed sales may be affected by availability and do not necessarily equal unconstrained demand.
- Inventory, stockout and promotion execution data are unavailable for causal investigation.
- Aggregate metrics can conceal local errors; alerts also depend on the chosen thresholds.
- PDF exports show only the visible portion of scrolling tables. The full alert CSV supports detailed review.
- Future improvements include unseen-period evaluation, department-level bias checks, prediction intervals and additional holiday, trend and price features.

## Author

Yuming Bi
