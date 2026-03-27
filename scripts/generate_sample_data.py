"""
Rev Ops Sample Data Generator
Generates realistic CRM-style data for practice SQL queries and dashboards
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import string

# Configuration
NUM_ACCOUNTS = 100
NUM_OPPORTUNITIES = 500
NUM_ACTIVITIES = 2000
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2024, 12, 31)

# Seed for reproducibility
np.random.seed(42)
random.seed(42)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def random_date(start, end):
    """Generate random date between start and end"""
    delta = end - start
    random_days = random.randint(0, delta.days)
    return start + timedelta(days=random_days)

def generate_id(prefix, length=15):
    """Generate Salesforce-style ID"""
    chars = string.ascii_uppercase + string.digits
    return prefix + ''.join(random.choices(chars, k=length))

def weighted_choice(choices, weights):
    """Make weighted random choice"""
    return random.choices(choices, weights=weights, k=1)[0]

# ============================================================================
# GENERATE ACCOUNTS
# ============================================================================

print("Generating accounts...")

industries = ['Technology', 'Healthcare', 'Finance', 'Retail', 'Manufacturing', 
              'Education', 'Media', 'Real Estate', 'Consulting', 'Other']
regions = ['North America', 'EMEA', 'APAC', 'LATAM']
sales_reps = ['Alice Johnson', 'Bob Smith', 'Carol Davis', 'David Wilson', 
              'Emma Brown', 'Frank Miller', 'Grace Lee', 'Henry Chen',
              'Iris Rodriguez', 'Jack Thompson']

accounts = []
for i in range(NUM_ACCOUNTS):
    # Employee count follows realistic distribution (more small companies)
    emp_bracket = weighted_choice(
        [50, 200, 500, 1000, 5000],
        [40, 30, 15, 10, 5]
    )
    employee_count = random.randint(int(emp_bracket * 0.8), int(emp_bracket * 1.2))
    
    # ARR roughly correlates with company size
    base_arr = employee_count * random.randint(100, 500)
    arr = round(base_arr * random.uniform(0.8, 1.5), 2)
    
    account = {
        'account_id': generate_id('001'),
        'account_name': f"Company_{i+1:03d} {random.choice(['Inc', 'Corp', 'LLC', 'Ltd'])}",
        'industry': random.choice(industries),
        'employee_count': employee_count,
        'arr': arr if random.random() > 0.3 else None,  # 30% don't have ARR yet (prospects)
        'created_date': random_date(START_DATE, END_DATE - timedelta(days=180)),
        'account_owner': random.choice(sales_reps),
        'region': random.choice(regions)
    }
    accounts.append(account)

accounts_df = pd.DataFrame(accounts)

# ============================================================================
# GENERATE OPPORTUNITIES
# ============================================================================

print("Generating opportunities...")

stages = ['Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost']
stage_probabilities = [10, 25, 50, 75, 100, 0]
lead_sources = ['Inbound', 'Outbound', 'Partner', 'Event', 'Referral', 'Website']

opportunities = []
for i in range(NUM_OPPORTUNITIES):
    account = accounts_df.sample(n=1).iloc[0]
    
    # Created date is after account created date
    created_date = random_date(
        account['created_date'], 
        END_DATE
    )
    
    # Close date is 30-120 days after created
    days_to_close = random.randint(30, 120)
    close_date = created_date + timedelta(days=days_to_close)
    
    # Stage progression (more opps in early stages)
    stage = weighted_choice(
        stages,
        [30, 25, 20, 12, 8, 5]
    )
    
    probability = stage_probabilities[stages.index(stage)]
    
    # Closed opps have is_closed=True
    is_closed = stage in ['Closed Won', 'Closed Lost']
    is_won = stage == 'Closed Won'
    
    # If not closed yet, close_date is in future
    if not is_closed and close_date < datetime.now():
        close_date = datetime.now() + timedelta(days=random.randint(10, 90))
    
    # Amount correlates with account size
    if account['employee_count']:
        base_amount = account['employee_count'] * random.randint(20, 100)
    else:
        base_amount = random.randint(5000, 50000)
    
    amount = round(base_amount * random.uniform(0.7, 1.5), 2)
    
    opp = {
        'opp_id': generate_id('006'),
        'account_id': account['account_id'],
        'opp_name': f"{account['account_name']} - {random.choice(['Expansion', 'New Business', 'Renewal', 'Upsell'])}",
        'amount': amount,
        'stage': stage,
        'probability': probability,
        'close_date': close_date.date(),
        'created_date': created_date.date(),
        'owner': account['account_owner'],
        'lead_source': random.choice(lead_sources),
        'is_closed': is_closed,
        'is_won': is_won
    }
    opportunities.append(opp)

opps_df = pd.DataFrame(opportunities)

# ============================================================================
# GENERATE OPPORTUNITY STAGE HISTORY
# ============================================================================

print("Generating stage history...")

stage_history = []
history_id = 1

for _, opp in opps_df.iterrows():
    current_stage_index = stages.index(opp['stage'])
    
    # Generate history for stages this opp has passed through
    current_date = datetime.combine(opp['created_date'], datetime.min.time())
    
    for stage_idx in range(current_stage_index + 1):
        stage_name = stages[stage_idx]
        
        # Days in each stage (realistic distribution)
        if stage_name == 'Prospecting':
            days_in_stage = random.randint(3, 15)
        elif stage_name == 'Qualification':
            days_in_stage = random.randint(5, 20)
        elif stage_name == 'Proposal':
            days_in_stage = random.randint(7, 30)
        elif stage_name == 'Negotiation':
            days_in_stage = random.randint(5, 45)
        else:  # Closed stages
            days_in_stage = 0
        
        history = {
            'history_id': history_id,
            'opp_id': opp['opp_id'],
            'stage': stage_name,
            'changed_date': current_date,
            'days_in_stage': days_in_stage
        }
        stage_history.append(history)
        
        current_date += timedelta(days=days_in_stage)
        history_id += 1

stage_history_df = pd.DataFrame(stage_history)

# ============================================================================
# GENERATE ACTIVITIES
# ============================================================================

print("Generating activities...")

activity_types = ['Call', 'Email', 'Meeting']
activity_type_weights = [40, 40, 20]

activities = []
activity_id = 1

# More activities for opps in later stages
for _, opp in opps_df.iterrows():
    stage_index = stages.index(opp['stage'])
    
    # Number of activities correlates with stage
    if stage_index == 0:  # Prospecting
        num_activities = random.randint(1, 5)
    elif stage_index == 1:  # Qualification
        num_activities = random.randint(3, 10)
    elif stage_index == 2:  # Proposal
        num_activities = random.randint(5, 15)
    elif stage_index == 3:  # Negotiation
        num_activities = random.randint(8, 20)
    else:  # Closed
        num_activities = random.randint(5, 25)
    
    for _ in range(num_activities):
        activity_date = random_date(
            datetime.combine(opp['created_date'], datetime.min.time()),
            datetime.combine(opp['close_date'], datetime.min.time()) if opp['is_closed'] else datetime.now()
        )
        
        activity = {
            'activity_id': activity_id,
            'opp_id': opp['opp_id'],
            'account_id': opp['account_id'],
            'activity_type': weighted_choice(activity_types, activity_type_weights),
            'activity_date': activity_date.date(),
            'owner': opp['owner']
        }
        activities.append(activity)
        activity_id += 1

activities_df = pd.DataFrame(activities)

# ============================================================================
# GENERATE CLOSED DEALS (for ARR tracking)
# ============================================================================

print("Generating closed deals...")

closed_won_opps = opps_df[opps_df['is_won'] == True]
closed_deals = []

for _, opp in closed_won_opps.iterrows():
    # Contract typically starts on close date
    contract_start = datetime.combine(opp['close_date'], datetime.min.time())
    
    # Annual contracts (12 months)
    contract_end = contract_start + timedelta(days=365)
    
    # ARR is the opp amount
    arr = opp['amount']
    mrr = round(arr / 12, 2)
    
    # Determine deal type
    account_existing_deals = closed_deals_temp = [d for d in closed_deals if d['account_id'] == opp['account_id']]
    if len(account_existing_deals) == 0:
        deal_type = 'new'
    elif random.random() > 0.7:
        deal_type = 'expansion'
        # Expansion deals are typically smaller
        arr = round(arr * random.uniform(0.3, 0.7), 2)
        mrr = round(arr / 12, 2)
    else:
        deal_type = 'renewal'
    
    # 10% of deals eventually churn
    churned_date = None
    if random.random() < 0.10:
        churn_days = random.randint(90, 365)
        churned_date = contract_start + timedelta(days=churn_days)
    
    deal = {
        'deal_id': generate_id('800'),
        'account_id': opp['account_id'],
        'opp_id': opp['opp_id'],
        'close_date': opp['close_date'],
        'contract_start_date': contract_start.date(),
        'contract_end_date': contract_end.date(),
        'arr': arr,
        'mrr': mrr,
        'deal_type': deal_type,
        'churned_date': churned_date.date() if churned_date else None
    }
    closed_deals.append(deal)

closed_deals_df = pd.DataFrame(closed_deals)

# ============================================================================
# GENERATE QUOTA TARGETS
# ============================================================================

print("Generating quota targets...")

quarters = ['2023-Q1', '2023-Q2', '2023-Q3', '2023-Q4', 
            '2024-Q1', '2024-Q2', '2024-Q3', '2024-Q4']

quota_targets = []
quota_id = 1

for rep in sales_reps:
    # Each rep gets increasing quota over time
    base_quota = random.randint(200000, 500000)
    
    for i, quarter in enumerate(quarters):
        # Quota increases ~10% per quarter
        quota_amount = round(base_quota * (1.1 ** i), 2)
        
        # Determine region (reps stay in same region)
        rep_region = accounts_df[accounts_df['account_owner'] == rep]['region'].mode()
        region = rep_region.iloc[0] if len(rep_region) > 0 else random.choice(regions)
        
        quota = {
            'quota_id': quota_id,
            'rep_name': rep,
            'quarter': quarter,
            'quota_amount': quota_amount,
            'region': region
        }
        quota_targets.append(quota)
        quota_id += 1

quota_targets_df = pd.DataFrame(quota_targets)

# ============================================================================
# EXPORT TO CSV
# ============================================================================

print("\nExporting to CSV files...")

accounts_df.to_csv('accounts.csv', index=False)
opps_df.to_csv('opportunities.csv', index=False)
stage_history_df.to_csv('opp_stage_history.csv', index=False)
activities_df.to_csv('activities.csv', index=False)
closed_deals_df.to_csv('closed_deals.csv', index=False)
quota_targets_df.to_csv('quota_targets.csv', index=False)

print("\n" + "="*60)
print("DATA GENERATION COMPLETE!")
print("="*60)
print(f"\nGenerated files:")
print(f"  - accounts.csv ({len(accounts_df)} records)")
print(f"  - opportunities.csv ({len(opps_df)} records)")
print(f"  - opp_stage_history.csv ({len(stage_history_df)} records)")
print(f"  - activities.csv ({len(activities_df)} records)")
print(f"  - closed_deals.csv ({len(closed_deals_df)} records)")
print(f"  - quota_targets.csv ({len(quota_targets_df)} records)")

print("\n" + "="*60)
print("QUICK STATS")
print("="*60)
print(f"\nOpportunities by Stage:")
print(opps_df['stage'].value_counts())
print(f"\nWin Rate: {(opps_df['is_won'].sum() / opps_df['is_closed'].sum() * 100):.1f}%")
print(f"\nTotal ARR (Active): ${closed_deals_df[closed_deals_df['churned_date'].isna()]['arr'].sum():,.2f}")
print(f"Total MRR (Active): ${closed_deals_df[closed_deals_df['churned_date'].isna()]['mrr'].sum():,.2f}")

print("\n" + "="*60)
print("NEXT STEPS")
print("="*60)
print("""
1. Create PostgreSQL database:
   createdb revops_practice

2. Load the SQL schema (from Day 1 of battle plan)

3. Import CSV files:
   psql revops_practice
   \\copy accounts FROM 'accounts.csv' CSV HEADER;
   \\copy opportunities FROM 'opportunities.csv' CSV HEADER;
   \\copy opp_stage_history FROM 'opp_stage_history.csv' CSV HEADER;
   \\copy activities FROM 'activities.csv' CSV HEADER;
   \\copy closed_deals FROM 'closed_deals.csv' CSV HEADER;
   \\copy quota_targets FROM 'quota_targets.csv' CSV HEADER;

4. Start building queries!
""")
