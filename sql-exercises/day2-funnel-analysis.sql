/*
==============================================================================
DAY 2: FUNNEL ANALYSIS QUERIES
==============================================================================
Author: Matthieu Sun
Date: 2026-03-27
Database: revops_practice
Purpose: Analyze sales funnel conversion rates and identify bottlenecks

Business Context:
Understanding where opportunities drop off in the sales process helps 
identify coaching opportunities and process improvements.

Prerequisites:
- opportunities table populated
- opp_stage_history table populated
==============================================================================
 */

-- -----------------------------------------------------------------------------
-- EXERCISE 1: Basic Funnel Conversion
-- -----------------------------------------------------------------------------
-- Business Question: What does our overall funnel look like?
-- Stakeholder: VP Sales
-- Frequency: Weekly review
-- Expected Insight: Identify stages with abnormal drop-off


-- Visualization: Funnel Chart
-- Issue with the way Metabase calculates the Closed Lost rate, as it currently uses Closed Lost/Closed Won. Cf Table view for the accurate number.
SELECT
  stage,
  COUNT(*) as opp_count
FROM
  opp_stage_history
GROUP BY
  stage
ORDER BY
  CASE stage
    WHEN 'Prospecting' THEN 1
    WHEN 'Qualification' THEN 2
    WHEN 'Proposal' THEN 3
    WHEN 'Negotiation' THEN 4
    WHEN 'Closed Won' THEN 5
    WHEN 'Closed Lost' THEN 6
  END;


-- Visualization: Table
SELECT 'Opportunities Count' AS title
	,Count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting') AS prospecting
	,count(DISTINCT opp_id) filter(WHERE stage = 'Qualification') AS qualification
	,count(DISTINCT opp_id) filter(WHERE stage = 'Proposal') AS proposal
	,count(DISTINCT opp_id) filter(WHERE stage = 'Negotiation') AS negotiation
	,count(DISTINCT opp_id) filter(WHERE stage = 'Closed Won') AS closed_won
	,count(DISTINCT opp_id) filter(WHERE stage = 'Closed Lost') AS closed_lost
FROM opp_stage_history

UNION ALL

SELECT 'Stage-to-stage Conversion Rates (%)' AS title
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS prospecting
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Qualification') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS qualification
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Proposal') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Qualification'), 0)) * 100 AS proposal
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Negotiation') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Proposal'), 0)) * 100 AS negotiation
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Closed Won') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Negotiation'), 0)) * 100 AS closed_won
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Closed Lost') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Closed Won'), 0)) * 100 AS closed_lost
FROM opp_stage_history

UNION ALL

SELECT 'Aggregate Conversion Rates (%)' AS title
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS prospecting
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Qualification') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS qualification
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Proposal') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS proposal
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Negotiation') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS negotiation
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Closed Won') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS closed_won
	,(cast(count(DISTINCT opp_id) filter(WHERE stage = 'Closed Lost') AS FLOAT) / NULLIF(count(DISTINCT opp_id) filter(WHERE stage = 'Prospecting'), 0)) * 100 AS closed_lost
FROM opp_stage_history


-- Key Insight: 
-- If Prospecting to Qualification drop is >40%, investigate lead quality


-- -----------------------------------------------------------------------------
-- EXERCISE 2: Time-Based Funnel
-- -----------------------------------------------------------------------------
-- Business Question: How has funnel performance changed month-over-month?
-- Stakeholder: Rev Ops
-- Frequency: Monthly
-- Expected Insight: Seasonal trends or degradation over time

-- Visualization: Funnel Chart
-- Issue with the way Metabase calculates the Closed Lost rate, as it currently uses Closed Lost/Closed Won. Cf Table view for the accurate number.
SELECT
  opp_stage_history.stage,
  COUNT(*) AS opp_count
FROM
  opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
WHERE 1=1 [[AND {{created_date}}]]
GROUP BY
  opp_stage_history.stage
ORDER BY
  CASE opp_stage_history.stage
    WHEN 'Prospecting' THEN 1
    WHEN 'Qualification' THEN 2
    WHEN 'Proposal' THEN 3
    WHEN 'Negotiation' THEN 4
    WHEN 'Closed Won' THEN 5
    WHEN 'Closed Lost' THEN 6
  END;

-- Visualization: Table
SELECT 'Opportunities Count' AS Title
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting') AS Prospecting
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS Qualification
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS Proposal
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS Negotiation
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS Closed_Won
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS Closed_Lost
FROM opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
WHERE 1 = 1 [[AND {{created_date}}]]

UNION ALL

SELECT 'Stage-to-stage Conversion Rates (%)' AS Title
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Prospecting
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Qualification
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification'), 0)) * 100 AS Proposal
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal'), 0)) * 100 AS Negotiation
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation'), 0)) * 100 AS Closed_Won
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation'), 0)) * 100 AS Closed_Lost
FROM opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
WHERE 1 = 1 [[AND {{created_date}}]]

UNION ALL

SELECT 'Aggregate Conversion Rates (%)' AS Title
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Prospecting
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Qualification
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Proposal
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Negotiation
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Closed_Won
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Closed_Lost
FROM opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
WHERE 1 = 1 [[AND {{created_date}}]]

-- Follow-up analysis needed if:
-- - Any stage shows >20% MoM decline
-- - Prospecting volume trending down for 3+ months


-- -----------------------------------------------------------------------------
-- EXERCISE 3: Segment-Based Funnel
-- -----------------------------------------------------------------------------
-- Business Question: Which lead sources convert best?
-- Stakeholder: Marketing + Sales
-- Frequency: Quarterly
-- Expected Insight: Optimize marketing spend based on conversion

-- Visualization: Funnel Chart
-- Issue with the way Metabase calculates the Closed Lost rate, as it currently uses Closed Lost/Closed Won. Cf Table view for the accurate number.
SELECT
  opp_stage_history.stage,
  COUNT(*) AS opp_count
FROM
  opp_stage_history
  LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
  LEFT JOIN accounts ON opportunities.account_id = accounts.account_id
WHERE
  1 = 1 
	[[AND {{lead_source}}]] 
	[[AND {{industry}}]]
	[[AND {{deal_size_lower}}]]
	[[AND {{deal_size_upper}}]]
GROUP BY
  opp_stage_history.stage
ORDER BY
  CASE opp_stage_history.stage
    WHEN 'Prospecting' THEN 1
    WHEN 'Qualification' THEN 2
    WHEN 'Proposal' THEN 3
    WHEN 'Negotiation' THEN 4
    WHEN 'Closed Won' THEN 5
    WHEN 'Closed Lost' THEN 6
  END;


-- Visualization: Table
SELECT 'Opportunities Count' AS Title
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting') AS Prospecting
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS Qualification
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS Proposal
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS Negotiation
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS Closed_Won
	,COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS Closed_Lost
FROM opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
LEFT JOIN accounts ON opportunities.account_id = accounts.account_id
WHERE 1 = 1
	[[AND {{lead_source}}]] 
	[[AND {{industry}}]]
	[[AND {{deal_size_lower}}]]
	[[AND {{deal_size_upper}}]]

UNION ALL

SELECT 'Stage-to-stage Conversion Rates (%)' AS Title
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Prospecting
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Qualification
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification'), 0)) * 100 AS Proposal
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal'), 0)) * 100 AS Negotiation
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation'), 0)) * 100 AS Closed_Won
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation'), 0)) * 100 AS Closed_Lost
FROM opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
LEFT JOIN accounts ON opportunities.account_id = accounts.account_id
WHERE 1 = 1
 	[[AND {{lead_source}}]] 
	[[AND {{industry}}]]
	[[AND {{deal_size_lower}}]]
	[[AND {{deal_size_upper}}]]

UNION ALL

SELECT 'Aggregate Conversion Rates (%)' AS Title
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Prospecting
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Qualification
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Proposal
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Negotiation
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Closed_Won
	,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS Closed_Lost
FROM opp_stage_history
LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
LEFT JOIN accounts ON opportunities.account_id = accounts.account_id
WHERE 1 = 1
	[[AND {{lead_source}}]] 
	[[AND {{industry}}]]
	[[AND {{deal_size_lower}}]]
	[[AND {{deal_size_upper}}]]

-- Action items based on results:
-- - Double down on sources with >25% win rate
-- - Investigate sources with <10% win rate (worth the CAC?)


-- -----------------------------------------------------------------------------
-- NOTES & LESSONS LEARNED
-- -----------------------------------------------------------------------------

/*
1. Always use NULLIF when dividing to avoid division by zero errors
2. CASE statements in ORDER BY allow custom sorting logic
3. Field filters [[AND {{column}}]] make queries reusable in dashboards

Next steps:
- Create Metabase dashboard to display queries with multiple filters
- Schedule weekly email report to VP Sales
 */