# QUICK START GUIDE - START HERE!

**Time to first query: 30 minutes**
**Time to first dashboard: 3 hours**

## IMMEDIATE SETUP (Do this today)

### Step 1: Install PostgreSQL (15 min)
**Mac:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Ubuntu/WSL:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo service postgresql start
```

**Windows:**
Download from: https://www.postgresql.org/download/windows/

### Step 2: Create Database (5 min)
```bash
createdb revops_practice
psql revops_practice
```

### Step 3: Run Schema Creation (5 min)

Copy-paste this into psql:

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

-- OPPORTUNITY HISTORY
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
    activity_type VARCHAR(50),
    activity_date DATE,
    owner VARCHAR(100)
);

-- CLOSED WON DEALS
CREATE TABLE closed_deals (
    deal_id VARCHAR(18) PRIMARY KEY,
    account_id VARCHAR(18) REFERENCES accounts(account_id),
    opp_id VARCHAR(18) REFERENCES opportunities(opp_id),
    close_date DATE,
    contract_start_date DATE,
    contract_end_date DATE,
    arr DECIMAL(12,2),
    mrr DECIMAL(12,2),
    deal_type VARCHAR(20),
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

### Step 4: Generate and Load Sample Data (5 min)

```bash
# Install pandas if you don't have it
pip install pandas numpy --break-system-packages

# Run the data generator
python generate_sample_data.py

# Import CSV files into PostgreSQL
psql revops_practice

\copy accounts FROM 'accounts.csv' CSV HEADER;
\copy opportunities FROM 'opportunities.csv' CSV HEADER;
\copy opp_stage_history FROM 'opp_stage_history.csv' CSV HEADER;
\copy activities FROM 'activities.csv' CSV HEADER;
\copy closed_deals FROM 'closed_deals.csv' CSV HEADER;
\copy quota_targets FROM 'quota_targets.csv' CSV HEADER;

-- Verify data loaded
SELECT 'accounts' as table_name, COUNT(*) FROM accounts
UNION ALL SELECT 'opportunities', COUNT(*) FROM opportunities
UNION ALL SELECT 'activities', COUNT(*) FROM activities
UNION ALL SELECT 'closed_deals', COUNT(*) FROM closed_deals;
```

---

## YOUR FIRST 5 SQL QUERIES (Start practicing NOW)

### Query 1: Basic Funnel
**Business Question:** What does our sales funnel look like?

```sql
SELECT 
    stage,
    COUNT(*) as opp_count,
    SUM(amount) as total_value,
    ROUND(AVG(amount), 2) as avg_deal_size,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_total
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

**Expected Output:**
```
stage         | opp_count | total_value | avg_deal_size | pct_of_total
--------------|-----------|-------------|---------------|-------------
Prospecting   |    150    |  15000000   |   100000.00   |    30.00
Qualification |    125    |  12500000   |   100000.00   |    25.00
...
```

**What this teaches:** Basic aggregation, ordering, percentages

---

### Query 2: Win Rate Analysis
**Business Question:** What's our win rate, and how does it vary by segment?

```sql
SELECT 
    lead_source,
    COUNT(*) as total_opps,
    COUNT(CASE WHEN is_won THEN 1 END) as won_count,
    COUNT(CASE WHEN is_closed AND NOT is_won THEN 1 END) as lost_count,
    ROUND(100.0 * COUNT(CASE WHEN is_won THEN 1 END) / 
          NULLIF(COUNT(CASE WHEN is_closed THEN 1 END), 0), 2) as win_rate,
    ROUND(AVG(CASE WHEN is_won THEN amount END), 2) as avg_won_deal_size
FROM opportunities
WHERE is_closed = true
GROUP BY lead_source
ORDER BY win_rate DESC;
```

**What this teaches:** Conditional aggregation, handling NULLs with NULLIF, CASE statements

---

### Query 3: Current ARR (Real-world metric)
**Business Question:** What's our current Annual Recurring Revenue?

```sql
SELECT 
    SUM(arr) as current_arr,
    COUNT(DISTINCT account_id) as active_customers,
    ROUND(AVG(arr), 2) as avg_arr_per_customer,
    SUM(CASE WHEN deal_type = 'new' THEN arr ELSE 0 END) as new_business_arr,
    SUM(CASE WHEN deal_type = 'expansion' THEN arr ELSE 0 END) as expansion_arr
FROM closed_deals
WHERE churned_date IS NULL;
```

**What this teaches:** Filtering for current state, revenue segmentation

---

### Query 4: Pipeline Coverage (Critical Rev Ops metric)
**Business Question:** Do we have enough pipeline to hit quota this quarter?

```sql
WITH current_quarter AS (
    SELECT 
        owner,
        SUM(amount) FILTER (WHERE is_won) as closed_revenue,
        SUM(amount * probability / 100.0) FILTER (WHERE NOT is_closed) as weighted_pipeline
    FROM opportunities
    WHERE close_date BETWEEN '2024-10-01' AND '2024-12-31'
    GROUP BY owner
),
quotas AS (
    SELECT 
        rep_name as owner,
        quota_amount
    FROM quota_targets
    WHERE quarter = '2024-Q4'
)
SELECT 
    q.owner,
    q.quota_amount,
    COALESCE(cq.closed_revenue, 0) as closed_revenue,
    q.quota_amount - COALESCE(cq.closed_revenue, 0) as remaining_quota,
    COALESCE(cq.weighted_pipeline, 0) as weighted_pipeline,
    ROUND(
        COALESCE(cq.weighted_pipeline, 0) / 
        NULLIF(q.quota_amount - COALESCE(cq.closed_revenue, 0), 0),
        2
    ) as coverage_ratio,
    CASE 
        WHEN (COALESCE(cq.weighted_pipeline, 0) / NULLIF(q.quota_amount - COALESCE(cq.closed_revenue, 0), 0)) >= 3 
            THEN '✓ Healthy'
        WHEN (COALESCE(cq.weighted_pipeline, 0) / NULLIF(q.quota_amount - COALESCE(cq.closed_revenue, 0), 0)) >= 2 
            THEN '⚠ Monitor'
        ELSE '✗ At Risk'
    END as status
FROM quotas q
LEFT JOIN current_quarter cq ON q.owner = cq.owner
ORDER BY coverage_ratio ASC;
```

**What this teaches:** CTEs, COALESCE, complex business logic, status indicators

---

### Query 5: MRR Movements (Advanced)
**Business Question:** How did MRR change last month?

```sql
WITH monthly_movements AS (
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
        -1 * SUM(mrr) as churn_mrr
    FROM closed_deals
    WHERE churned_date IS NOT NULL
    GROUP BY 1
)
SELECT 
    mm.month,
    SUM(CASE WHEN mm.deal_type = 'new' THEN mm.mrr_amount ELSE 0 END) as new_mrr,
    SUM(CASE WHEN mm.deal_type = 'expansion' THEN mm.mrr_amount ELSE 0 END) as expansion_mrr,
    SUM(CASE WHEN mm.deal_type = 'renewal' THEN mm.mrr_amount ELSE 0 END) as renewal_mrr,
    COALESCE(mc.churn_mrr, 0) as churn_mrr,
    SUM(mm.mrr_amount) + COALESCE(mc.churn_mrr, 0) as net_new_mrr
FROM monthly_movements mm
LEFT JOIN monthly_churn mc ON mm.month = mc.month
GROUP BY mm.month, mc.churn_mrr
ORDER BY mm.month DESC
LIMIT 12;
```

**What this teaches:** Window functions (via DATE_TRUNC), multiple CTEs, complex aggregations

---

## INSTALL METABASE (Your dashboard tool)

### Docker Method (Easiest - 5 minutes)

```bash
# Pull and run Metabase
docker run -d -p 3000:3000 --name metabase metabase/metabase

# Wait 60 seconds for startup, then open browser to:
# http://localhost:3000

# Follow setup wizard:
# 1. Create admin account
# 2. Add database connection:
#    - Database type: PostgreSQL
#    - Name: Rev Ops Practice
#    - Host: host.docker.internal (Mac/Windows) or your local IP (Linux)
#    - Port: 5432
#    - Database name: revops_practice
#    - Username: your_username
#    - Password: (if you set one)
```

### Alternative: Direct Install

Download from: https://www.metabase.com/start/oss/

---

## YOUR FIRST DASHBOARD (Hour 1-3)

### Create These 6 Visualizations:

**1. Current ARR - Number Card**
- Question type: Custom Question
- Paste Query 3 above
- Visualization: Number
- Display: current_arr field
- Format as currency

**2. Funnel Chart**
- Use Query 1
- Visualization: Funnel
- Use stage and opp_count

**3. Win Rate by Lead Source - Bar Chart**
- Use Query 2
- Visualization: Bar chart
- X-axis: lead_source
- Y-axis: win_rate

**4. Pipeline Coverage - Table**
- Use Query 4
- Visualization: Table
- Conditional formatting:
  - coverage_ratio >= 3: Green
  - coverage_ratio >= 2: Yellow
  - coverage_ratio < 2: Red

**5. MRR Waterfall - Stacked Bar**
- Use Query 5
- Visualization: Bar (stacked)
- X-axis: month
- Y-axis: new_mrr, expansion_mrr, churn_mrr

**6. Top Opportunities - Table**
```sql
SELECT 
    o.opp_name,
    a.account_name,
    o.amount,
    o.stage,
    o.close_date,
    o.owner
FROM opportunities o
JOIN accounts a ON o.account_id = a.account_id
WHERE o.is_closed = false
ORDER BY o.amount DESC
LIMIT 20;
```

### Assemble Dashboard:
1. Create new dashboard: "Rev Ops Overview"
2. Add all 6 visualizations
3. Arrange in grid layout
4. Add date filter (applies to all)
5. Save and share link

---

## DAILY PRACTICE ROUTINE

**Morning (30 min) - SQL Drills:**
- Pick 1 query from the battle plan
- Write it from scratch (no copy-paste)
- Verify results
- Document in GitHub

**Afternoon (2 hours) - Dashboard Building:**
- Build 2-3 new visualizations
- Add to dashboard
- Polish formatting

**Evening (30 min) - Review & Document:**
- Commit SQL queries to GitHub
- Screenshot dashboards
- Update portfolio README

---

## TROUBLESHOOTING

**"Permission denied" when creating database:**
```bash
sudo -u postgres createdb revops_practice
sudo -u postgres psql
CREATE USER your_username WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE revops_practice TO your_username;
```

**"Connection refused" in Metabase:**
- Check PostgreSQL is running: `pg_isready`
- Check port: `psql -h localhost -p 5432 -U your_username revops_practice`
- For Docker Metabase, use `host.docker.internal` instead of `localhost`

**"No data" in visualizations:**
- Verify data loaded: `SELECT COUNT(*) FROM opportunities;`
- Check date filters aren't excluding all data
- Verify SQL query runs in psql first

---

## FIRST WEEK MILESTONES

**By End of Day 1:**
- [ ] Database set up with sample data
- [ ] All 5 starter queries running
- [ ] Metabase connected

**By End of Day 3:**
- [ ] First dashboard complete (6+ visualizations)
- [ ] 10 SQL queries documented in GitHub

**By End of Day 7:**
- [ ] 3 dashboards complete
- [ ] 15+ SQL queries in portfolio
- [ ] GitHub README with screenshots

---

## HELPFUL COMMANDS

**PostgreSQL:**
```bash
# Connect to database
psql revops_practice

# List tables
\dt

# Describe table structure
\d opportunities

# View query execution plan
EXPLAIN ANALYZE SELECT ...;

# Export query results to CSV
\copy (SELECT ...) TO 'output.csv' CSV HEADER;
```

**Git:**
```bash
# Initialize repo
git init
git add .
git commit -m "Initial commit: Rev Ops portfolio setup"
git remote add origin https://github.com/yourusername/revops-portfolio.git
git push -u origin main

# Daily commits
git add .
git commit -m "Day 2: Added funnel analysis queries"
git push
```

---

## WHEN YOU'RE STUCK

**SQL Not Working?**
1. Test each part of the query separately
2. Use LIMIT 10 while debugging
3. Check for NULL values (use COALESCE)
4. Verify date formats

**Dashboard Looks Wrong?**
1. Check data types (numbers vs strings)
2. Verify aggregation logic
3. Test query in SQL first
4. Check for filtering issues

**Can't Figure Out a Query?**
1. Break it into smaller parts
2. Start with simple SELECT, add complexity
3. Use CTEs to organize logic
4. Google: "PostgreSQL [what you're trying to do]"

---

## YOU'RE READY!

You now have:
✓ Working database with realistic data
✓ 5 starter queries to practice
✓ Dashboard tool set up
✓ Clear first-day goals

**Next step:** Open the full battle plan (revops_battleplan.md) and start Day 1.

**Time check:** If you can run all 5 queries successfully and see results in Metabase, you're ready to accelerate through the 2-week plan.

Good luck! 🚀
