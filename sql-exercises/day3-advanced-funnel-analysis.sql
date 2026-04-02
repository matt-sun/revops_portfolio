/*
==============================================================================
DAY 3: ADVANCED FUNNEL ANALYSIS QUERIES
==============================================================================
Author: Matthieu Sun
Date: 2026-04-01
Database: revops_practice
Purpose: Analyze advanced sales funnel conversion rates and identify bottlenecks

Business Context:
Understanding where opportunities drop off in the sales process helps 
identify coaching opportunities and process improvements.

Prerequisites:
- opportunities table populated
- opp_stage_history table populated
==============================================================================
 */

-- -----------------------------------------------------------------------------
-- EXERCISE 1: Velocity Metrics
-- -----------------------------------------------------------------------------
-- Business Question: What is our sales velocity?
-- Stakeholder: VP Sales
-- Frequency: Weekly review
-- Expected Insight: Identify stages with abnormal duration

-- Visualization: Table
SELECT
	stage,
	AVG(days_in_stage) AS avg_days,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_in_stage) AS median_days
FROM opp_stage_history 
GROUP BY stage
ORDER BY
  CASE opp_stage_history.stage
    WHEN 'Prospecting' THEN 1
    WHEN 'Qualification' THEN 2
    WHEN 'Proposal' THEN 3
    WHEN 'Negotiation' THEN 4
    WHEN 'Closed Won' THEN 5
    WHEN 'Closed Lost' THEN 6
  END;


-- Follow-up analysis needed if:
-- - Any stage shows MoM duration increase
-- - Any stage duration trending up for 3+ months


-- -----------------------------------------------------------------------------
-- EXERCISE 2: Funnel Leak Detection
-- -----------------------------------------------------------------------------
-- Business Question: Are there any stages with unusually high drop-off rates?
-- Stakeholder: Rev Ops
-- Frequency: Monthly
-- Expected Insight: Seasonal trends or degradation over time

-- Visualization: Table
WITH target_conv_rates AS (
	SELECT
		100.0 AS target_prospecting
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Prospecting'), 0)) * 100 AS target_qualification
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Qualification'), 0)) * 100 AS target_proposal
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Proposal'), 0)) * 100 AS target_negotiation
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Negotiation'), 0)) * 100 AS target_closed_Won
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Negotiation'), 0)) * 100 AS target_closed_Lost
	FROM opp_stage_history
),
current_conv_rates AS (
	SELECT
		100.0 AS cur_prospecting
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS cur_qualification
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification'), 0)) * 100 AS cur_proposal
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal'), 0)) * 100 AS cur_negotiation
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation'), 0)) * 100 AS cur_closed_Won
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation'), 0)) * 100 AS cur_closed_Lost
	FROM opp_stage_history
	LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
	WHERE 1 = 1 [[AND {{created_date}}]]
), target_agg_conv_rates AS (
	SELECT
		100.0 AS target_prospecting
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Prospecting'), 0)) * 100 AS target_qualification
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Prospecting'), 0)) * 100 AS target_proposal
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Prospecting'), 0)) * 100 AS target_negotiation
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Prospecting'), 0)) * 100 AS target_closed_Won
		,(CAST(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_id) FILTER(WHERE stage = 'Prospecting'), 0)) * 100 AS target_closed_Lost
	FROM opp_stage_history
),
current_agg_conv_rates AS (
	SELECT
		100.0 AS cur_prospecting
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Qualification') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS cur_qualification
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Proposal') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS cur_proposal
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Negotiation') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS cur_negotiation
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Won') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS cur_closed_Won
		,(CAST(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Closed Lost') AS FLOAT) / NULLIF(COUNT(DISTINCT opp_stage_history.opp_id) FILTER(WHERE opp_stage_history.stage = 'Prospecting'), 0)) * 100 AS cur_closed_Lost
	FROM opp_stage_history
	LEFT JOIN opportunities ON opp_stage_history.opp_id = opportunities.opp_id
	WHERE 1 = 1 [[AND {{created_date}}]]
)

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

SELECT 'Target Stage-to-stage Conversion Rates (%)' AS Title
	,target_prospecting
	,target_qualification
	,target_proposal
	,target_negotiation
	,target_closed_Won
	,target_closed_Lost
FROM target_conv_rates

UNION ALL

SELECT 'Stage-to-stage Conversion Rates (%)' AS Title
	,cur_prospecting
	,cur_qualification
	,cur_proposal
	,cur_negotiation
	,cur_closed_Won
	,cur_closed_Lost
FROM current_conv_rates

UNION ALL

SELECT 'Variation vs Target Stage-to-stage Conversion Rates (%)' AS Title
	,(cur_prospecting - target_prospecting) AS Prospecting
	,(cur_qualification - target_qualification) AS Qualification
	,(cur_proposal - target_proposal) AS Proposal
	,(cur_negotiation - target_negotiation) AS Negotiation
	,(cur_closed_Won - target_closed_Won) AS Closed_Won
	,(cur_closed_Lost - target_closed_Lost) AS Closed_Lost
FROM current_conv_rates
CROSS JOIN target_conv_rates

UNION ALL

SELECT 'Target Aggregate Conversion Rates (%)' AS Title
	,target_prospecting
	,target_qualification
	,target_proposal
	,target_negotiation
	,target_closed_Won
	,target_closed_Lost
FROM target_agg_conv_rates

UNION ALL

SELECT 'Aggregate Conversion Rates (%)' AS Title
	,cur_prospecting
	,cur_qualification
	,cur_proposal
	,cur_negotiation
	,cur_closed_Won
	,cur_closed_Lost
FROM current_agg_conv_rates

UNION ALL

SELECT 'Variation vs Target Aggregate Conversion Rates (%)' AS Title
	,(cur_prospecting - target_prospecting) AS Prospecting
	,(cur_qualification - target_qualification) AS Qualification
	,(cur_proposal - target_proposal) AS Proposal
	,(cur_negotiation - target_negotiation) AS Negotiation
	,(cur_closed_Won - target_closed_Won) AS Closed_Won
	,(cur_closed_Lost - target_closed_Lost) AS Closed_Lost
FROM current_agg_conv_rates
CROSS JOIN target_agg_conv_rates


-- Key Insight: 
-- Flag stages where conversion is <10% of historical average, investigate lead quality


-- -----------------------------------------------------------------------------
-- NOTES & LESSONS LEARNED
-- -----------------------------------------------------------------------------

/*
1. Always use NULLIF when dividing to avoid division by zero errors
2. CASE statements in ORDER BY allow custom sorting logic
3. Field filters [[AND {{column}}]] make queries reusable in dashboards

 */