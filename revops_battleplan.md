# 2-WEEK REV OPS SQL & DASHBOARDING BATTLE PLAN

**Mission:** Transform from "SQL-aware Rev Ops" to "data-fluent Rev Ops leader" with portfolio-ready dashboards

**Daily Commitment:** 8-10 hours/day (full-time intensity)
**End State:** 3 portfolio dashboards + GitHub repo + interview-ready case studies

---

## WEEK 1: SQL MASTERY & DATA FOUNDATION

### DAY 1: Environment Setup + Rev Ops Data Modeling

**Morning (4 hours): Infrastructure**
- [ ] Install Metabase locally (Docker: `docker run -p 3000:3000 metabase/metabase`)
- [ ] Set up PostgreSQL database named `revops_practice`
- [ ] Create GitHub repo: `revops-portfolio`
- [ ] Set up basic README structure

**Afternoon (4 hours): Build Your Practice Database**

Create realistic Rev Ops tables with sample data:

```sql
-- ACCOUNTS TABLE
CREATE TABLE accounts (
    account_id VARCHAR(18) PRIMARY KEY,
    account_name VARCHAR(255),
    industry VARCHAR(100),
    employee_count INT,
    arr DECIMAL(12,2),
    created_date DATE,
    account_owner VARCHAR(100),
    region VARCHAR(50)
);

-- OPPORTUNITIES TABLE
CREATE TABLE opportunities (
    opp_id VARCHAR(18) PRIMARY KEY,
    account_id VARCHAR(18) REFERENCES accounts(account_id),
    opp_name VARCHAR(255),
    amount DECIMAL(12,2),
    stage VARCHAR(50),
    probability INT,
    close_date DATE,
    created_date DATE,
    owner VARCHAR(100),
    lead_source VARCHAR(100),
    is_closed BOOLEAN,
    is_won BOOLEAN
);

-- OPPORTUNITY HISTORY (for stage changes)
CREATE TABLE opp_stage_history (
    history_id SERIAL PRIMARY KEY,
    opp_id VARCHAR(18) REFERENCES opportunities(opp_id),
    stage VARCHAR(50),
    changed_date TIMESTAMP,
    days_in_stage INT
);

-- ACTIVITIES TABLE
CREATE TABLE activities (
    activity_id SERIAL PRIMARY KEY,
    opp_id VARCHAR(18) REFERENCES opportunities(opp_id),
    account_id VARCHAR(18) REFERENCES accounts(account_id),
    activity_type VARCHAR(50), -- call, email, meeting
    activity_date DATE,
    owner VARCHAR(100)
);

-- CLOSED WON DEALS (for ARR tracking)
CREATE TABLE closed_deals (
    deal_id VARCHAR(18) PRIMARY KEY,
    account_id VARCHAR(18) REFERENCES accounts(account_id),
    opp_id VARCHAR(18) REFERENCES opportunities(opp_id),
    close_date DATE,
    contract_start_date DATE,
    contract_end_date DATE,
    arr DECIMAL(12,2),
    mrr DECIMAL(12,2),
    deal_type VARCHAR(20), -- new, expansion, renewal
    churned_date DATE
);

-- QUOTA TABLE
CREATE TABLE quota_targets (
    quota_id SERIAL PRIMARY KEY,
    rep_name VARCHAR(100),
    quarter VARCHAR(10),
    quota_amount DECIMAL(12,2),
    region VARCHAR(50)
);
```

**Evening (2 hours): Generate Sample Data**

Use Python script to generate 500+ realistic records:

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Sample data generation script
# Create 100 accounts, 500 opportunities, 2000 activities
# Use realistic distributions for stages, amounts, conversion rates

# Example for opportunities:
stages = ['Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost']
stage_probabilities = [10, 25, 50, 75, 100, 0]

# Generate and export to CSV, then import to PostgreSQL
```

**Deliverable:** Working database with 6 tables populated with realistic data

---

### DAY 2: SQL Foundations - Funnel Analysis

**Morning (4 hours): Core Query Patterns**

**Exercise 1: Basic Funnel**
```sql
-- Calculate conversion rates by stage
-- Expected output: Stage name, # of opps, conversion to next stage, overall conversion to closed won

SELECT 
    stage,
    COUNT(*) as opp_count,
    -- Your code here
FROM opportunities
GROUP BY stage
ORDER BY 
    CASE stage
        WHEN 'Prospecting' THEN 1
        WHEN 'Qualification' THEN 2
        WHEN 'Proposal' THEN 3
        WHEN 'Negotiation' THEN 4
        WHEN 'Closed Won' THEN 5
        WHEN 'Closed Lost' THEN 6
    END;
```

**Exercise 2: Time-Based Funnel**
```sql
-- Funnel analysis by month created
-- Shows how conversion rates change over time
-- Hint: Use DATE_TRUNC and conditional aggregation
```

**Exercise 3: Segment-Based Funnel**
```sql
-- Compare funnel performance by:
-- - Lead source
-- - Deal size (small <10K, medium 10-50K, large >50K)
-- - Industry
```

**Afternoon (4 hours): Advanced Funnel Patterns**

**Exercise 4: Velocity Metrics**
```sql
-- Calculate average days in each stage
-- Use opp_stage_history table
-- Join with opportunities to get current stage
WITH stage_durations AS (
    -- Your CTE here
)
SELECT 
    stage,
    AVG(days_in_stage) as avg_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_in_stage) as median_days
FROM stage_durations
GROUP BY stage;
```

**Exercise 5: Funnel Leak Detection**
```sql
-- Identify stages with abnormal drop-off
-- Compare expected vs actual conversion
-- Flag stages where conversion is <80% of historical average
```

**Evening (2 hours): Document & Commit**
- [ ] Create `/sql-exercises/day2-funnel-analysis.sql` in GitHub
- [ ] Add comments explaining business logic
- [ ] Screenshot key query results

**Deliverable:** 5 working SQL queries with business context documentation

---

### DAY 3: SQL - Revenue Metrics (ARR/MRR Analysis)

**Morning (4 hours): MRR Movements**

**Exercise 6: Monthly MRR Waterfall**
```sql
-- Calculate MRR changes month-over-month:
-- Starting MRR + New + Expansion - Contraction - Churn = Ending MRR

WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', contract_start_date) as month,
        SUM(CASE WHEN deal_type = 'new' THEN mrr ELSE 0 END) as new_mrr,
        SUM(CASE WHEN deal_type = 'expansion' THEN mrr ELSE 0 END) as expansion_mrr,
        -- Add contraction and churn logic
    FROM closed_deals
    WHERE churned_date IS NULL OR churned_date > contract_start_date
    GROUP BY 1
)
SELECT 
    month,
    new_mrr,
    expansion_mrr,
    -- Calculate running total
FROM monthly_metrics
ORDER BY month;
```

**Exercise 7: Cohort Retention Analysis**
```sql
-- Track revenue retention by customer cohort (month they signed)
-- Show month 1, 3, 6, 12 retention rates
-- Hint: Use self-joins and date arithmetic
```

**Afternoon (4 hours): ARR Analytics**

**Exercise 8: ARR by Segment**
```sql
-- Current ARR breakdown by:
-- - Customer size (SMB, Mid-market, Enterprise)
-- - Industry
-- - Region
-- Include growth rate vs same time last year
```

**Exercise 9: Logo Retention vs Revenue Retention**
```sql
-- Compare customer retention (logo count) vs revenue retention (ARR)
-- By cohort month
-- Shows if you're growing within accounts or just retaining
```

**Exercise 10: Churn Risk Modeling (Data Prep)**
```sql
-- Identify accounts with churn risk indicators:
-- - Contract ending in next 90 days
-- - ARR decreased in last 6 months
-- - Low activity count (< 5 activities in last 90 days)
-- - No expansion in first 12 months
```

**Evening (2 hours): Build Data Quality Checks**
```sql
-- Create queries to detect common data issues:
-- - Opportunities without accounts
-- - Closed won opps without deals in closed_deals table
-- - Negative MRR values
-- - Future close dates in historical data
-- - Duplicate opportunity IDs
```

**Deliverable:** Revenue analytics SQL library + data quality checklist

---

### DAY 4: SQL - Sales Performance & Forecasting

**Morning (4 hours): Rep Performance Metrics**

**Exercise 11: Quota Attainment Dashboard Query**
```sql
-- By rep, by quarter:
-- - Quota
-- - Closed Won revenue
-- - Attainment %
-- - Ranking
-- - Pipeline coverage (open pipeline / remaining quota)

WITH quarterly_performance AS (
    SELECT 
        o.owner,
        EXTRACT(YEAR FROM o.close_date) || '-Q' || EXTRACT(QUARTER FROM o.close_date) as quarter,
        SUM(CASE WHEN o.is_won THEN o.amount ELSE 0 END) as closed_revenue,
        SUM(CASE WHEN NOT o.is_closed THEN o.amount * o.probability / 100.0 ELSE 0 END) as weighted_pipeline
    FROM opportunities o
    WHERE o.close_date >= '2024-01-01'
    GROUP BY 1, 2
)
SELECT 
    qp.*,
    qt.quota_amount,
    -- Your calculations here
FROM quarterly_performance qp
LEFT JOIN quota_targets qt ON qp.owner = qt.rep_name AND qp.quarter = qt.quarter;
```

**Exercise 12: Activity Efficiency**
```sql
-- Analyze activity-to-conversion correlation
-- Activities per deal by rep
-- Meeting-to-opp conversion rate
-- Call-to-meeting conversion rate
```

**Afternoon (4 hours): Pipeline Analytics**

**Exercise 13: Pipeline Coverage Analysis**
```sql
-- For current quarter and next quarter:
-- - Total open pipeline
-- - Weighted pipeline (amount * probability)
-- - Pipeline needed (quota - closed won)
-- - Coverage ratio (weighted pipeline / remaining quota)
-- By rep, by region, by segment
```

**Exercise 14: Deal Slip Analysis**
```sql
-- Identify opportunities that have slipped close dates
-- How many times has close date changed?
-- Average slip duration
-- Correlation between slips and eventual outcome (won/lost)
```

**Exercise 15: Pipeline Generation Trends**
```sql
-- Month-over-month pipeline creation
-- By lead source
-- Compare pipeline created vs pipeline needed (historical)
-- Flag months with insufficient generation
```

**Evening (2 hours): Forecasting Framework**
```sql
-- Build a simple forecast model:
-- Historical win rate by stage, by rep
-- Apply to current open pipeline
-- Create 3 scenarios: conservative, likely, best case
```

**Deliverable:** Sales analytics SQL suite (15 total queries documented)

---

### DAY 5: Dashboard Design Principles & Wireframing

**Morning (4 hours): Study Dashboard Examples**

**Research Task:**
- [ ] Find 10 Rev Ops dashboard examples (Pinterest, Google Images, vendor sites)
- [ ] Critique each: What works? What's cluttered? What's missing?
- [ ] Identify common patterns:
  - KPI cards at top
  - Trend lines for time-series
  - Tables for drill-down details
  - Filters (date range, owner, region)

**Create a Dashboard Design Doc:**
```markdown
# Dashboard Design Principles

## Types of Dashboards I'll Build:
1. Executive Revenue Health
2. Sales Performance & Pipeline
3. Data Quality Monitoring

## Design Rules:
- Maximum 6-8 visualizations per dashboard
- Tell a story (top to bottom, left to right)
- Colors: Green (good), Red (bad), Yellow (warning), Blue (neutral)
- Always include comparison period (vs last month, vs target)

## Metrics Hierarchy:
### North Star: ARR Growth Rate
### Primary: MRR, Pipeline Coverage, Win Rate
### Secondary: ASP, Sales Cycle Length, Activity Volume
### Diagnostic: Stage conversion rates, churn by segment, etc.
```

**Afternoon (4 hours): Wireframe Your 3 Dashboards**

Use Excalidraw, Figma, or even paper + photo:

**Dashboard 1: Executive Revenue Health**
- [ ] Sketch layout (mobile mockup size)
- [ ] Define each component:
  - Current ARR (big number)
  - MRR waterfall chart (this month)
  - ARR trend line (last 12 months)
  - New vs expansion vs churn breakdown
  - Top 10 accounts by ARR table
  - Churn risk alerts

**Dashboard 2: Sales Performance**
- [ ] Quota attainment by rep (bar chart)
- [ ] Pipeline coverage by rep (table, color-coded)
- [ ] Win rate trends (line chart)
- [ ] Pipeline funnel (sankey or funnel chart)
- [ ] Activity leaderboard
- [ ] Deal slip report (table)

**Dashboard 3: Pipeline & Forecast**
- [ ] Current quarter forecast (gauge chart)
- [ ] Next quarter pipeline build (vs target line)
- [ ] Pipeline by stage (stacked bar)
- [ ] Top opportunities (table, sortable)
- [ ] Lead source performance
- [ ] Stage velocity metrics

**Evening (2 hours): Connect Metabase to Database**
- [ ] Launch Metabase at localhost:3000
- [ ] Add PostgreSQL connection
- [ ] Create "Rev Ops Practice" database connection
- [ ] Test with simple query: `SELECT COUNT(*) FROM opportunities`
- [ ] Familiarize with UI (Questions, Dashboards, Collections)

**Deliverable:** 3 wireframe designs + Metabase connected

---

### DAY 6: Build Dashboard 1 - Executive Revenue Health

**Full Day (8-10 hours): Implementation**

**Step 1: Create Individual Visualizations (Metabase "Questions")**

**Viz 1: Current ARR (Number Card)**
```sql
SELECT SUM(arr) as current_arr
FROM closed_deals
WHERE churned_date IS NULL;
```
- [ ] Format as currency
- [ ] Add comparison to last month (use date filter)

**Viz 2: MRR Waterfall (Bar Chart)**
```sql
-- Monthly MRR movements (last month)
SELECT 
    'Starting MRR' as category, LAG(total_mrr) OVER (ORDER BY month) as value
    -- Union with new, expansion, contraction, churn
FROM monthly_mrr_summary
WHERE month = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month');
```
- [ ] Use horizontal bar chart
- [ ] Color code: green for additions, red for reductions

**Viz 3: ARR Trend (Line Chart)**
```sql
-- Last 12 months ARR
WITH monthly_arr AS (
    SELECT 
        DATE_TRUNC('month', d) as month,
        SUM(arr) as total_arr
    FROM closed_deals cd
    CROSS JOIN generate_series('2023-01-01'::date, CURRENT_DATE, '1 day'::interval) d
    WHERE cd.contract_start_date <= d 
      AND (cd.churned_date IS NULL OR cd.churned_date > d)
    GROUP BY 1
)
SELECT * FROM monthly_arr
WHERE month >= CURRENT_DATE - INTERVAL '12 months'
ORDER BY month;
```
- [ ] Add trend line
- [ ] Show growth rate annotation

**Viz 4: Revenue Mix (Stacked Area Chart)**
```sql
-- New vs Expansion ARR over time
SELECT 
    month,
    SUM(CASE WHEN deal_type = 'new' THEN arr ELSE 0 END) as new_arr,
    SUM(CASE WHEN deal_type = 'expansion' THEN arr ELSE 0 END) as expansion_arr
FROM closed_deals
GROUP BY month
ORDER BY month;
```

**Viz 5: Top Accounts Table**
```sql
-- Top 10 by ARR with health indicators
SELECT 
    a.account_name,
    cd.arr,
    cd.contract_end_date,
    DATEDIFF('day', CURRENT_DATE, cd.contract_end_date) as days_to_renewal,
    COUNT(DISTINCT act.activity_id) as recent_activities
FROM accounts a
JOIN closed_deals cd ON a.account_id = cd.account_id
LEFT JOIN activities act ON a.account_id = act.account_id 
    AND act.activity_date >= CURRENT_DATE - INTERVAL '90 days'
WHERE cd.churned_date IS NULL
GROUP BY 1,2,3,4
ORDER BY cd.arr DESC
LIMIT 10;
```

**Viz 6: Churn Risk Alerts**
```sql
-- Accounts at risk
SELECT 
    a.account_name,
    cd.arr,
    cd.contract_end_date,
    CASE 
        WHEN recent_activities < 3 THEN 'Low Engagement'
        WHEN days_to_renewal < 60 THEN 'Renewal Due Soon'
        ELSE 'Monitor'
    END as risk_reason
FROM (
    -- Subquery with account metrics
) risk_accounts
WHERE risk_score > 50
ORDER BY risk_score DESC;
```

**Step 2: Assemble Dashboard**
- [ ] Create new dashboard: "Executive Revenue Health"
- [ ] Arrange visualizations per wireframe
- [ ] Add text cards for context/titles
- [ ] Set up date filter (applies to all visualizations)
- [ ] Configure auto-refresh (every 24 hours)

**Step 3: Polish & Test**
- [ ] Adjust chart colors for consistency
- [ ] Add descriptions to each visualization
- [ ] Test filters work correctly
- [ ] Take screenshots for portfolio
- [ ] Screen record a walkthrough (Loom/QuickTime)

**Deliverable:** Completed Dashboard 1 + walkthrough video

---

### DAY 7: Build Dashboard 2 - Sales Performance

**Morning (4 hours): Rep Performance Visualizations**

**Viz 1: Quota Attainment by Rep (Bar Chart)**
```sql
-- Current quarter
SELECT 
    owner,
    quota_amount,
    closed_revenue,
    ROUND(100.0 * closed_revenue / quota_amount, 1) as attainment_pct
FROM quarterly_performance
WHERE quarter = '2024-Q1'
ORDER BY attainment_pct DESC;
```
- [ ] Horizontal bar chart
- [ ] Color code: >100% green, 80-100% yellow, <80% red
- [ ] Add reference line at 100%

**Viz 2: Pipeline Coverage Table**
```sql
-- Rep-level coverage for current quarter
SELECT 
    owner,
    quota_amount,
    closed_revenue,
    quota_amount - closed_revenue as remaining_quota,
    weighted_pipeline,
    ROUND(weighted_pipeline / NULLIF(quota_amount - closed_revenue, 0), 2) as coverage_ratio
FROM rep_pipeline_summary
WHERE quarter = CURRENT_QUARTER
ORDER BY coverage_ratio ASC; -- Show lowest coverage first
```
- [ ] Conditional formatting on coverage_ratio
- [ ] Sort by coverage (ascending) to highlight gaps

**Viz 3: Win Rate Trends (Line Chart)**
```sql
-- Monthly win rate by rep (top 5 reps)
SELECT 
    DATE_TRUNC('month', close_date) as month,
    owner,
    100.0 * COUNT(CASE WHEN is_won THEN 1 END) / COUNT(*) as win_rate
FROM opportunities
WHERE is_closed = true
    AND owner IN (SELECT owner FROM top_5_reps)
GROUP BY 1, 2
ORDER BY 1, 2;
```
- [ ] Multi-line chart (one line per rep)
- [ ] Add overall average as reference line

**Afternoon (4 hours): Pipeline Visualizations**

**Viz 4: Funnel Chart**
```sql
-- Current open pipeline by stage
SELECT 
    stage,
    COUNT(*) as opp_count,
    SUM(amount) as total_value
FROM opportunities
WHERE is_closed = false
GROUP BY stage
ORDER BY 
    CASE stage
        WHEN 'Prospecting' THEN 1
        WHEN 'Qualification' THEN 2
        WHEN 'Proposal' THEN 3
        WHEN 'Negotiation' THEN 4
    END;
```
- [ ] Use funnel visualization type
- [ ] Show both count and value

**Viz 5: Activity Leaderboard (Table)**
```sql
-- Last 30 days activity by rep
SELECT 
    owner,
    COUNT(CASE WHEN activity_type = 'call' THEN 1 END) as calls,
    COUNT(CASE WHEN activity_type = 'meeting' THEN 1 END) as meetings,
    COUNT(CASE WHEN activity_type = 'email' THEN 1 END) as emails,
    COUNT(*) as total_activities
FROM activities
WHERE activity_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY owner
ORDER BY total_activities DESC;
```

**Viz 6: Deal Slip Report (Table)**
```sql
-- Opportunities that have changed close date
SELECT 
    opp_name,
    owner,
    amount,
    original_close_date,
    current_close_date,
    DATEDIFF('day', original_close_date, current_close_date) as days_slipped,
    stage
FROM opportunity_slip_tracking
WHERE days_slipped > 0
ORDER BY amount DESC;
```

**Evening (2 hours): Assemble Dashboard 2**
- [ ] Arrange per wireframe
- [ ] Add filters: Date range, Owner, Region
- [ ] Test interactivity (click-through filtering)
- [ ] Document insights in text cards
- [ ] Record walkthrough

**Deliverable:** Completed Dashboard 2

---

## WEEK 2: ADVANCED SKILLS & PORTFOLIO COMPLETION

### DAY 8: Build Dashboard 3 - Pipeline & Forecast

**Morning (4 hours): Forecast Visualizations**

**Viz 1: Quarterly Forecast Gauge**
```sql
-- Current quarter: Quota vs Forecast vs Closed
SELECT 
    SUM(quota_amount) as quota,
    SUM(closed_revenue) as closed,
    SUM(closed_revenue + weighted_pipeline) as forecast
FROM quarterly_summary
WHERE quarter = CURRENT_QUARTER;
```
- [ ] Use gauge/progress chart
- [ ] Show 3 markers: closed, forecast, quota

**Viz 2: Pipeline Build Tracking (Combo Chart)**
```sql
-- Monthly pipeline creation vs target
SELECT 
    DATE_TRUNC('month', created_date) as month,
    SUM(amount) as pipeline_created,
    AVG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', created_date) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as three_month_avg,
    pipeline_target.target
FROM opportunities
LEFT JOIN pipeline_target ON DATE_TRUNC('month', created_date) = pipeline_target.month
GROUP BY 1
ORDER BY 1;
```
- [ ] Bar chart for actual
- [ ] Line for 3-month average and target

**Afternoon (4 hours): Pipeline Deep-Dive**

**Viz 3: Pipeline by Stage (Stacked Bar)**
```sql
-- Weekly snapshot of pipeline by stage
SELECT 
    DATE_TRUNC('week', snapshot_date) as week,
    stage,
    SUM(amount) as pipeline_value
FROM pipeline_snapshots
WHERE snapshot_date >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY 1, 2
ORDER BY 1, 2;
```

**Viz 4: Top Opportunities (Interactive Table)**
```sql
-- Deals closing this quarter, sorted by amount
SELECT 
    opp_name,
    account_name,
    amount,
    stage,
    probability,
    close_date,
    owner,
    DATEDIFF('day', CURRENT_DATE, close_date) as days_until_close
FROM opportunities o
JOIN accounts a ON o.account_id = a.account_id
WHERE close_date BETWEEN CURRENT_QUARTER_START AND CURRENT_QUARTER_END
    AND is_closed = false
ORDER BY amount DESC;
```
- [ ] Enable sorting
- [ ] Click to drill into opportunity details

**Viz 5: Lead Source Performance (Funnel by Source)**
```sql
-- Conversion metrics by lead source
SELECT 
    lead_source,
    COUNT(*) as total_opps,
    COUNT(CASE WHEN is_won THEN 1 END) as won_opps,
    100.0 * COUNT(CASE WHEN is_won THEN 1 END) / COUNT(*) as win_rate,
    AVG(CASE WHEN is_won THEN amount END) as avg_deal_size,
    SUM(CASE WHEN is_won THEN amount ELSE 0 END) as total_revenue
FROM opportunities
WHERE created_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY lead_source
ORDER BY total_revenue DESC;
```

**Viz 6: Stage Velocity (Heatmap/Table)**
```sql
-- Average days in each stage by month
SELECT 
    DATE_TRUNC('month', changed_date) as month,
    stage,
    AVG(days_in_stage) as avg_days
FROM opp_stage_history
GROUP BY 1, 2
ORDER BY 1, 2;
```

**Evening (2 hours): Final Assembly**
- [ ] Build Dashboard 3
- [ ] Add interactivity between charts
- [ ] Set up scheduled email reports
- [ ] Full dashboard walkthrough video

**Deliverable:** Completed Dashboard 3

---

### DAY 9: Dashboard Polish & Advanced Features

**Morning (4 hours): Enhance All Dashboards**

**Add Advanced Features:**
- [ ] **Dashboard 1 (Executive):**
  - Add drill-down from ARR chart to account details
  - Create "Export to PDF" functionality
  - Add YoY comparison toggle
  
- [ ] **Dashboard 2 (Sales):**
  - Add rep selector dropdown
  - Create "My Performance" personal view
  - Add goal lines to all relevant charts
  
- [ ] **Dashboard 3 (Pipeline):**
  - Add scenario modeling (adjust win rates)
  - Create alert thresholds (pipeline < 3x coverage)
  - Add historical forecast accuracy chart

**Performance Optimization:**
```sql
-- Create materialized views for complex queries
CREATE MATERIALIZED VIEW mv_monthly_arr AS
SELECT 
    DATE_TRUNC('month', d) as month,
    -- Complex ARR calculation
FROM ...;

-- Refresh strategy
REFRESH MATERIALIZED VIEW mv_monthly_arr;
```

**Afternoon (4 hours): Create Data Quality Dashboard**

This is your differentiator! Most candidates don't think about this.

**Dashboard 4: Rev Ops Data Health (BONUS)**

**Viz 1: Data Completeness Scorecard**
```sql
-- % of records with required fields populated
SELECT 
    'Accounts' as object,
    100.0 * COUNT(CASE WHEN industry IS NOT NULL THEN 1 END) / COUNT(*) as industry_completeness,
    100.0 * COUNT(CASE WHEN employee_count IS NOT NULL THEN 1 END) / COUNT(*) as size_completeness,
    100.0 * COUNT(CASE WHEN account_owner IS NOT NULL THEN 1 END) / COUNT(*) as owner_completeness
FROM accounts
UNION ALL
SELECT 
    'Opportunities',
    100.0 * COUNT(CASE WHEN lead_source IS NOT NULL THEN 1 END) / COUNT(*),
    100.0 * COUNT(CASE WHEN close_date IS NOT NULL THEN 1 END) / COUNT(*),
    100.0 * COUNT(CASE WHEN amount > 0 THEN 1 END) / COUNT(*)
FROM opportunities;
```

**Viz 2: Data Quality Issues Table**
```sql
-- Active data quality problems
SELECT 
    issue_type,
    COUNT(*) as issue_count,
    priority,
    example_record_id
FROM (
    SELECT 'Opp without Account' as issue_type, opp_id as example_record_id, 'High' as priority
    FROM opportunities WHERE account_id IS NULL
    UNION ALL
    SELECT 'Closed Won without Deal Record', opp_id, 'Critical'
    FROM opportunities WHERE is_won = true AND opp_id NOT IN (SELECT opp_id FROM closed_deals)
    UNION ALL
    SELECT 'Negative Amount', opp_id, 'High'
    FROM opportunities WHERE amount < 0
    -- Add more checks
) issues
GROUP BY 1, 3
ORDER BY 
    CASE priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 END,
    issue_count DESC;
```

**Viz 3: Data Hygiene Trends**
```sql
-- Track data quality improvements over time
SELECT 
    DATE_TRUNC('week', checked_date) as week,
    issue_type,
    COUNT(*) as open_issues
FROM data_quality_log
GROUP BY 1, 2
ORDER BY 1, 2;
```

**Evening (2 hours): Screenshots & Documentation**
- [ ] Capture all dashboard screenshots (full page + individual charts)
- [ ] Create `/dashboards/` folder in GitHub
- [ ] Write README for each dashboard explaining:
  - Business problem it solves
  - Key metrics included
  - How to use it
  - Sample insights

**Deliverable:** 4 polished dashboards with documentation

---

### DAY 10: Portfolio Packaging & GitHub

**Morning (4 hours): Build Your Portfolio Site**

**Create Comprehensive README.md:**

```markdown
# Rev Ops Analytics Portfolio
*by [Your Name]*

## Overview
This repository demonstrates production-ready SQL and dashboarding skills for Revenue Operations leadership roles in high-growth startups.

## Skills Demonstrated
- Advanced SQL (window functions, CTEs, cohort analysis)
- Dashboard design (Metabase)
- Revenue metrics (ARR/MRR, retention, forecasting)
- Sales analytics (pipeline, quota attainment, forecasting)
- Data quality monitoring

## Projects

### 1. Executive Revenue Health Dashboard
**Problem:** Leadership needs real-time visibility into ARR growth drivers and churn risks.

**Solution:** Built a comprehensive revenue dashboard tracking:
- Current ARR with MoM growth
- MRR waterfall (new, expansion, contraction, churn)
- 12-month ARR trend with cohort analysis
- Top accounts with health scoring
- At-risk account alerts

**Key Insight:** Discovered that expansion ARR grew 40% QoQ while new logo ARR declined 15%, signaling need to rebalance GTM motion.

[View Dashboard Screenshot](dashboards/executive-revenue-health.png)
[SQL Queries](sql-exercises/arr-analysis.sql)

### 2. Sales Performance Dashboard
[Similar structure]

### 3. Pipeline & Forecast Dashboard
[Similar structure]

### 4. Data Quality Monitoring (Bonus)
[Similar structure]

## SQL Query Library
- [Funnel Analysis](sql-exercises/funnel-analysis.sql)
- [ARR Metrics](sql-exercises/arr-metrics.sql)
- [Quota Attainment](sql-exercises/quota-attainment.sql)
- [Pipeline Coverage](sql-exercises/pipeline-coverage.sql)
- [Data Quality Checks](sql-exercises/data-quality.sql)

## Setup Instructions
[How to reproduce this locally]

## About Me
[Your background + LinkedIn]
```

**Afternoon (4 hours): Create SQL Documentation**

For each major query, create a documented version:

```sql
/*
QUERY NAME: Monthly MRR Waterfall Analysis
BUSINESS PURPOSE: Track month-over-month changes in recurring revenue
STAKEHOLDER: CFO, VP Sales
REFRESH CADENCE: Daily
LAST UPDATED: 2024-03-06

LOGIC OVERVIEW:
1. Calculate starting MRR (prior month ending balance)
2. Add new MRR (new customers)
3. Add expansion MRR (upsells, cross-sells)
4. Subtract contraction MRR (downgrades)
5. Subtract churn MRR (cancelled customers)
6. Result = ending MRR

ASSUMPTIONS:
- MRR is calculated from closed_deals table
- Expansion is identified by deal_type = 'expansion'
- Churn is determined by churned_date field

KNOWN ISSUES:
- Does not account for mid-month changes (uses contract_start_date)
- Expansion MRR may double-count if multiple expansions in same month

SAMPLE OUTPUT:
| month      | starting_mrr | new_mrr | expansion_mrr | contraction_mrr | churn_mrr | ending_mrr |
|------------|--------------|---------|---------------|-----------------|-----------|------------|
| 2024-02-01 | 450000       | 25000   | 15000         | -5000           | -10000    | 475000     |
*/

WITH monthly_changes AS (
    SELECT 
        DATE_TRUNC('month', contract_start_date) as month,
        deal_type,
        SUM(mrr) as mrr_amount
    FROM closed_deals
    WHERE contract_start_date >= '2024-01-01'
    GROUP BY 1, 2
),
monthly_churn AS (
    SELECT 
        DATE_TRUNC('month', churned_date) as month,
        -1 * SUM(mrr) as churn_amount
    FROM closed_deals
    WHERE churned_date IS NOT NULL
    GROUP BY 1
)
SELECT 
    mc.month,
    LAG(SUM(mc.mrr_amount)) OVER (ORDER BY mc.month) as starting_mrr,
    SUM(CASE WHEN mc.deal_type = 'new' THEN mc.mrr_amount ELSE 0 END) as new_mrr,
    SUM(CASE WHEN mc.deal_type = 'expansion' THEN mc.mrr_amount ELSE 0 END) as expansion_mrr,
    SUM(CASE WHEN mc.deal_type = 'contraction' THEN mc.mrr_amount ELSE 0 END) as contraction_mrr,
    COALESCE(mch.churn_amount, 0) as churn_mrr,
    SUM(mc.mrr_amount) + COALESCE(mch.churn_amount, 0) as ending_mrr
FROM monthly_changes mc
LEFT JOIN monthly_churn mch ON mc.month = mch.month
GROUP BY mc.month, mch.churn_amount
ORDER BY mc.month;
```

Document all 15 core queries this way.

**Evening (2 hours): Video Content**

**Create 3 Loom Videos:**
1. **Portfolio Overview (3 min)**
   - Quick tour of GitHub repo
   - Show each dashboard briefly
   - Explain your approach

2. **Deep Dive: Executive Dashboard (5 min)**
   - Walk through each visualization
   - Explain business logic
   - Show how you'd use it in a real scenario

3. **SQL Showcase (5 min)**
   - Pick your most impressive query
   - Explain the business problem
   - Walk through the code
   - Show the output

**Deliverable:** Complete GitHub portfolio with videos

---

### DAY 11: Interview Prep - Case Study Creation

**Morning (4 hours): Build Mock Client Case Study**

**Scenario:** Series B SaaS company, $10M ARR, 50 AEs, struggling with forecast accuracy

**Your Deliverable: "90-Day Rev Ops Audit & Implementation Plan"**

Create a slide deck (Google Slides or PowerPoint):

**Slide 1: Executive Summary**
- Current state assessment
- Key findings (3-5 bullets)
- Recommended roadmap

**Slide 2: Data Landscape Audit**
- Systems reviewed (CRM, billing, product analytics)
- Data quality score (use your data quality dashboard framework)
- Critical gaps identified

**Slide 3: Forecast Accuracy Analysis**
- Current accuracy rate
- Root causes (based on your pipeline analysis)
- Benchmark vs industry standard

**Slide 4: Dashboard Recommendations**
- Show wireframe of 3 dashboards you'd build
- Map to stakeholder needs (CEO, VP Sales, AEs)
- Implementation timeline

**Slide 5: 90-Day Plan**
```
Week 1-2: Data Cleanup & Infrastructure
- Audit CRM data quality
- Build data quality monitoring
- Standardize field definitions

Week 3-4: Core Dashboards Build
- Executive Revenue Health
- Sales Performance
- Pipeline & Forecast

Week 5-8: Process Implementation
- Train sales team on pipeline hygiene
- Implement weekly forecast review cadence
- Build automated alerts

Week 9-12: Optimization & Scale
- A/B test dashboard layouts
- Build custom views per role
- Create self-service analytics layer
```

**Slide 6: Expected Outcomes**
- Forecast accuracy: 65% → 85%
- Data completeness: 70% → 95%
- Time to insight: 2 days → 2 hours

**Afternoon (4 hours): Prepare "Take-Home Assignment"**

Create a reusable template for interview assignments:

**"Imagine a company gives you a CSV of their opportunity data and asks you to build a pipeline health analysis in 3 hours."**

**Your Template Structure:**

1. **Data Validation Script (15 min)**
```python
import pandas as pd

# Quick data quality checks
df = pd.read_csv('opportunities.csv')
print(f"Total records: {len(df)}")
print(f"Date range: {df['created_date'].min()} to {df['created_date'].max()}")
print(f"Missing values:\n{df.isnull().sum()}")
print(f"Unique stages: {df['stage'].unique()}")
```

2. **Core SQL Queries (45 min)**
- Funnel conversion by stage
- Win rate by segment
- Pipeline coverage calculation
- Top deals at risk

3. **Quick Dashboard (90 min)**
- Import to Metabase
- Build 4-6 key visualizations
- Create one summary dashboard

4. **Executive Summary (30 min)**
- Top 3 insights
- Top 3 recommendations
- Next steps

**Practice this end-to-end so you can execute it flawlessly under time pressure.**

**Evening (2 hours): Common Interview Questions**

Prepare answers with examples from your portfolio:

**Q: "Walk me through how you'd improve our sales forecast accuracy."**
**A:** [Reference your forecast dashboard, explain your methodology]

**Q: "How do you handle conflicting metric definitions between teams?"**
**A:** [Explain semantic layer concept, show how you documented queries]

**Q: "Show me a time you identified a major data quality issue."**
**A:** [Use your data quality dashboard as example]

**Q: "Build a query to calculate..."**
**A:** [Have 5-10 queries memorized that you can write on whiteboard]

**Deliverable:** Case study deck + take-home template

---

### DAY 12: Advanced SQL - Window Functions & Optimization

**Morning (4 hours): Master Window Functions**

**Exercise 16: Running Totals**
```sql
-- Cumulative ARR by month
SELECT 
    month,
    arr,
    SUM(arr) OVER (ORDER BY month) as cumulative_arr,
    SUM(arr) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_3month_arr
FROM monthly_arr;
```

**Exercise 17: Ranking & Percentiles**
```sql
-- Rank reps by quota attainment within each region
SELECT 
    rep_name,
    region,
    attainment_pct,
    RANK() OVER (PARTITION BY region ORDER BY attainment_pct DESC) as regional_rank,
    PERCENT_RANK() OVER (ORDER BY attainment_pct) as percentile_rank
FROM rep_performance;
```

**Exercise 18: Lead/Lag for Period Comparisons**
```sql
-- Compare this month's MRR to last month
SELECT 
    month,
    mrr,
    LAG(mrr, 1) OVER (ORDER BY month) as last_month_mrr,
    mrr - LAG(mrr, 1) OVER (ORDER BY month) as mom_change,
    100.0 * (mrr - LAG(mrr, 1) OVER (ORDER BY month)) / LAG(mrr, 1) OVER (ORDER BY month) as mom_growth_pct
FROM monthly_mrr;
```

**Exercise 19: Moving Averages for Smoothing**
```sql
-- 3-month moving average of win rate
SELECT 
    month,
    win_rate,
    AVG(win_rate) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as ma_3month,
    AVG(win_rate) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) as ma_6month
FROM monthly_win_rates;
```

**Exercise 20: Cohort Analysis (Advanced)**
```sql
-- Customer retention by cohort month
WITH cohorts AS (
    SELECT 
        account_id,
        DATE_TRUNC('month', MIN(contract_start_date)) as cohort_month
    FROM closed_deals
    GROUP BY account_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) as cohort_size
    FROM cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT 
        c.cohort_month,
        DATE_TRUNC('month', cd.contract_start_date) as activity_month,
        COUNT(DISTINCT cd.account_id) as active_accounts
    FROM cohorts c
    JOIN closed_deals cd ON c.account_id = cd.account_id
    WHERE cd.churned_date IS NULL OR cd.churned_date > cd.contract_start_date
    GROUP BY 1, 2
)
SELECT 
    ca.cohort_month,
    ca.activity_month,
    EXTRACT('month' FROM AGE(ca.activity_month, ca.cohort_month)) as months_since_signup,
    ca.active_accounts,
    cs.cohort_size,
    100.0 * ca.active_accounts / cs.cohort_size as retention_pct
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.activity_month;
```

**Afternoon (4 hours): Query Optimization**

**Learn to Optimize Slow Queries:**

**Before:**
```sql
-- Slow query (scans entire table)
SELECT *
FROM opportunities
WHERE EXTRACT(YEAR FROM close_date) = 2024;
```

**After:**
```sql
-- Faster (uses index on close_date)
SELECT *
FROM opportunities
WHERE close_date >= '2024-01-01' AND close_date < '2025-01-01';
```

**Create Indexes:**
```sql
-- Add indexes on commonly filtered/joined columns
CREATE INDEX idx_opp_close_date ON opportunities(close_date);
CREATE INDEX idx_opp_account_id ON opportunities(account_id);
CREATE INDEX idx_opp_owner ON opportunities(owner);
CREATE INDEX idx_opp_stage ON opportunities(stage);

-- Composite index for common query pattern
CREATE INDEX idx_opp_stage_closedate ON opportunities(stage, close_date);
```

**Use EXPLAIN to Analyze:**
```sql
EXPLAIN ANALYZE
SELECT COUNT(*) 
FROM opportunities
WHERE stage = 'Negotiation' AND close_date >= CURRENT_DATE;
```

**Materialized Views for Complex Calculations:**
```sql
-- Instead of calculating ARR on every query
CREATE MATERIALIZED VIEW mv_current_arr AS
SELECT 
    account_id,
    SUM(arr) as total_arr
FROM closed_deals
WHERE churned_date IS NULL
GROUP BY account_id;

-- Refresh nightly
REFRESH MATERIALIZED VIEW mv_current_arr;
```

**Evening (2 hours): Build SQL Cheat Sheet**

Create a personal reference guide:

```markdown
# Rev Ops SQL Patterns

## ARR Calculations
[Your go-to ARR query]

## MRR Waterfall
[Template query]

## Cohort Analysis
[Template with explanation]

## Win Rate by Segment
[Template]

## Pipeline Coverage
[Template]

## Velocity Metrics
[Template]

## Common Pitfalls to Avoid:
- Using EXTRACT(YEAR) instead of date ranges (kills indexes)
- Not handling NULL values in divisions (use NULLIF)
- Forgetting to filter out test/deleted records
- Using SELECT * instead of specific columns
```

**Deliverable:** Advanced SQL mastery + cheat sheet

---

### DAY 13: Looker/Tableau Exploration + Alternative Tools

**Morning (4 hours): Looker Trial Setup**

**Option 1: Looker (Recommended if targeting enterprise)**
- [ ] Sign up for Looker free trial
- [ ] Connect to your PostgreSQL database
- [ ] Complete Looker University basic training (2-3 hours)
- [ ] Rebuild ONE of your Metabase dashboards in Looker

**Learning Focus:**
- LookML basics (dimensions, measures)
- Explores (how tables join)
- Building looks (individual visualizations)
- Assembling dashboards
- Drilling & filtering

**Option 2: Tableau Public (Free, widely recognized)**
- [ ] Download Tableau Public
- [ ] Complete "Getting Started" tutorial
- [ ] Connect to CSV exports from your database
- [ ] Rebuild one dashboard

**Afternoon (4 hours): Tool Comparison Document**

**Create "Tool Evaluation Matrix":**

| Feature | Metabase | Looker | Tableau | When to Use |
|---------|----------|--------|---------|-------------|
| Ease of setup | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | Metabase for quick wins |
| SQL flexibility | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Looker for complex logic |
| Visualization options | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Tableau for presentations |
| Semantic layer | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Looker for governance |
| Collaboration | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | All good |
| Cost | Free | $$$$$ | Free (Public) | Consider budget |

**Your Positioning:**
"I've built production dashboards in Metabase and have working knowledge of Looker/Tableau. I focus on understanding business requirements first, then selecting the right tool for the job."

**Evening (2 hours): Modern Data Stack Overview**

**Understand the ecosystem:**

```
Data Sources (CRM, Product, Support)
    ↓
Extraction Layer (Fivetran, Stitch, Airbyte)
    ↓
Data Warehouse (Snowflake, BigQuery, Redshift)
    ↓
Transformation Layer (dbt) ← YOU SHOULD KNOW THIS EXISTS
    ↓
BI Layer (Looker, Tableau, Metabase)
    ↓
End Users (Execs, Sales, CS)
```

**Read up on:**
- [ ] What is dbt? (15 min on getdbt.com)
- [ ] Why use a semantic layer? (Looker's approach)
- [ ] Reverse ETL (sending data back to CRM)

**Deliverable:** Looker/Tableau familiarity + tool comparison doc

---

### DAY 14: Final Polish, Practice Presentations, Deploy

**Morning (3 hours): Final GitHub Polish**

**Checklist:**
- [ ] All SQL files properly commented
- [ ] README.md has clear navigation
- [ ] Screenshots embedded in markdown
- [ ] Video links working
- [ ] License file added (MIT)
- [ ] .gitignore configured (no sensitive data)
- [ ] Requirements.txt for Python scripts
- [ ] Setup instructions tested (can someone else replicate?)

**Create a Landing Page (Optional but Impressive):**

Simple HTML portfolio page:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Rev Ops Analytics Portfolio - [Your Name]</title>
    <style>
        body { font-family: Arial; max-width: 900px; margin: 50px auto; }
        .dashboard { border: 1px solid #ddd; padding: 20px; margin: 20px 0; }
        img { max-width: 100%; }
    </style>
</head>
<body>
    <h1>Revenue Operations Analytics Portfolio</h1>
    <p>Demonstrating production-ready SQL and dashboarding for high-growth startups</p>
    
    <div class="dashboard">
        <h2>Executive Revenue Health</h2>
        <img src="dashboards/exec-revenue.png">
        <p>[Description]</p>
        <a href="https://github.com/yourusername/repo">View SQL →</a>
    </div>
    
    <!-- Repeat for other dashboards -->
</body>
</html>
```

Host on GitHub Pages (free).

**Afternoon (3 hours): Mock Interview Practice**

**Practice answering with STAR method:**

**Q: "Tell me about a time you used data to influence a business decision."**

**Situation:** In my portfolio project, I analyzed a mock company's revenue data and noticed...

**Task:** I needed to identify why forecast accuracy was low and recommend improvements.

**Action:** I built a pipeline velocity dashboard that revealed deals were sitting in "Negotiation" stage 40% longer than average, indicating either pricing friction or champion changes. I created an automated alert system and designed a weekly review process.

**Result:** The analysis showed this could improve forecast accuracy from 65% to 85% and reduce deal slippage by 30%.

**Practice 10 common questions:**
1. Walk me through your SQL expertise
2. How do you approach building a new dashboard?
3. What metrics matter most for a Series B SaaS company?
4. How do you handle stakeholders with conflicting data requests?
5. Explain ARR vs MRR vs Bookings
6. How do you ensure data quality?
7. What's your experience with [specific tool]?
8. How do you prioritize competing requests?
9. Tell me about a complex analysis you've done
10. What questions would you ask me about our Rev Ops stack?

**Evening (2 hours): LinkedIn & Application Materials**

**Update LinkedIn:**
- [ ] Add "Revenue Operations Analyst" to headline
- [ ] Update About section to mention:
  - SQL proficiency (window functions, CTEs, optimization)
  - Dashboard expertise (Metabase, exposure to Looker/Tableau)
  - Rev Ops domain knowledge (ARR, pipeline, forecasting)
- [ ] Featured section: Link to your GitHub portfolio
- [ ] Skills: Add SQL, PostgreSQL, Data Visualization, Revenue Operations, SaaS Metrics

**Create Application Boilerplate:**

**Cover Letter Template:**
```
Dear Hiring Manager,

I'm reaching out about the Revenue Operations role at [Company]. With my background in Rev Ops and recent intensive upskilling in SQL and dashboarding, I'm excited to contribute to [Company's] data-driven sales operations.

In preparing for this transition to a more data-centric Rev Ops role, I built a comprehensive analytics portfolio demonstrating:

- Advanced SQL for revenue analytics (ARR tracking, cohort analysis, pipeline forecasting)
- Production-ready dashboards for executive, sales, and operational stakeholders
- Data quality monitoring and governance frameworks

My portfolio includes three core dashboards addressing typical Series B/C challenges:
[Brief description of each]

You can view my work at: [GitHub link]

I'd love to discuss how I can apply these skills to [Company's specific challenge mentioned in JD].

Best,
[Your Name]
```

**Email to Recruiters:**
```
Subject: Rev Ops Analyst with SQL/Dashboarding Portfolio

Hi [Name],

I'm a Revenue Operations professional with [X years] experience who recently completed intensive training in SQL and data visualization. I've built a portfolio of production-ready dashboards for Rev Ops use cases.

I'm actively seeking roles where I can combine my operational expertise with my new technical skills. Would [Company] have any relevant openings?

Portfolio: [link]
LinkedIn: [link]

Happy to chat if there's a fit!

[Your Name]
```

**Final Deliverable:** Complete, polished, interview-ready portfolio

---

## BONUS MATERIALS

### Advanced Challenges (If You Have Extra Time)

**Challenge 1: Build a Forecasting Model**
Use Python + scikit-learn to build a simple regression model predicting close probability based on opportunity characteristics.

**Challenge 2: dbt Project**
Set up dbt Cloud (free tier) and create a simple transformation pipeline:
- Source: Raw opportunity data
- Models: Staging → Intermediate → Mart layers
- Tests: Data quality constraints
- Documentation: Auto-generated docs site

**Challenge 3: API Integration**
Build a Python script that:
- Pulls data from Salesforce API (use developer sandbox)
- Transforms it
- Loads into PostgreSQL
- Triggers dashboard refresh

**Challenge 4: Real-Time Dashboard**
Set up a streaming dashboard using:
- Simulated live data (Python script generating events)
- WebSocket connection
- Real-time chart updates in React

### Resource Library

**SQL Learning:**
- Mode Analytics SQL Tutorial
- PostgreSQL Exercises (pgexercises.com)
- SQL Murder Mystery (fun learning game)
- Select Star SQL (selectstarsql.com)

**Dashboard Design:**
- "Storytelling with Data" by Cole Nussbaumer Knaflic
- "The Big Book of Dashboards" by Steve Wexler
- Metabase documentation
- Looker University (free courses)

**Rev Ops Metrics:**
- "SaaS Metrics 2.0" by David Skok
- Tomasz Tunguz blog (tomtunguz.com)
- SaaStr resources
- Metric Maven newsletter

**Communities:**
- RevOps Co-op (Slack)
- Locally Optimistic (Slack)
- r/businessintelligence
- r/dataengineering
- r/sql

### Daily Schedule Template

**6:00 AM - Wake up, review daily goals**
**7:00 AM - Deep work session 1 (3 hours)** ← Hardest technical work
**10:00 AM - Break**
**10:30 AM - Deep work session 2 (2.5 hours)** ← SQL exercises
**1:00 PM - Lunch + walk**
**2:00 PM - Deep work session 3 (2.5 hours)** ← Dashboard building
**4:30 PM - Break**
**5:00 PM - Review, documentation, admin (1.5 hours)**
**6:30 PM - Done for the day**

**Keys to success:**
- No distractions during deep work (phone off, no Slack/email)
- Time-box tasks (use Pomodoro: 50 min work, 10 min break)
- Document as you go (don't leave it for "later")
- Commit to GitHub daily (maintains momentum)

---

## SUCCESS METRICS

By Day 14, you should have:

**Technical Skills:**
- [ ] Can write complex SQL queries (window functions, CTEs) in <30 min
- [ ] Can build a dashboard from scratch in <2 hours
- [ ] Can explain data modeling decisions clearly
- [ ] Can optimize slow queries
- [ ] Can identify data quality issues

**Portfolio Artifacts:**
- [ ] GitHub repo with 15+ documented SQL queries
- [ ] 3-4 production-quality dashboards
- [ ] 3 walkthrough videos
- [ ] Case study deck
- [ ] Take-home assignment template

**Interview Readiness:**
- [ ] Can confidently discuss each portfolio project
- [ ] Can write SQL on a whiteboard
- [ ] Can critique dashboard designs
- [ ] Can explain Rev Ops metrics in depth
- [ ] Can speak to modern data stack trends

**Job Search Ready:**
- [ ] Updated LinkedIn
- [ ] Application templates
- [ ] Portfolio links shareable
- [ ] Reference check list prepared

---

## FINAL PREP CHECKLIST

**Before you start applying:**
- [ ] Test GitHub repo on a fresh browser (incognito mode)
- [ ] Watch your own videos (check audio quality)
- [ ] Have 3 people review your portfolio (peers, mentors)
- [ ] Practice your "portfolio walkthrough" 5 times
- [ ] Screenshot all dashboards (backup if live demo fails)
- [ ] Prepare answers to "why did you upskill now?"
- [ ] Practice technical interview questions (SQL on whiteboard)

**When you land an interview:**
- [ ] Research their tech stack (LinkedIn, Glassdoor, job description)
- [ ] Identify their likely pain points (stage, team size, growth rate)
- [ ] Customize your case study to their context
- [ ] Prepare 3 questions about their data maturity
- [ ] Offer to do a working session as part of interview

---

## YOU'VE GOT THIS!

This is an aggressive timeline, but absolutely achievable with full-time focus. The key differentiators in your favor:

1. **Real Rev Ops experience** - you understand the business context
2. **Python knowledge** - puts you ahead of 80% of candidates
3. **Demonstrable work** - portfolio beats resume every time
4. **Growth mindset** - you're proving you can learn quickly

Remember: Most candidates will have deeper tool expertise. Your edge is combining technical skills with business judgment. Lean into that.

When you're in interviews, frame it this way:

"I spent [X years] in Rev Ops understanding the strategic challenges. I recently invested two intensive weeks building the technical skills to solve those challenges with data. Here's what I built..."

Good luck! 🚀
