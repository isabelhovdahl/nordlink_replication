"""
02_tables_descriptive.py
========================
Generates all descriptive statistics tables for:

    Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
    "European market integration and price convergence:
     A panel quantile regression analysis of NordLink"
    Energy Policy

Tables produced
---------------
Table 1       : tab01_stats_price.tex   -- Descriptive statistics for the day-ahead
                                           price in NO2 and Germany (mean, min, max,
                                           std dev, skewness, kurtosis), by period.
App. Table A2 : tabA2_mean_values.tex   -- Mean and std dev of all variables by period.

Input data
----------
data_NO2.dta  : panel data for NO2 
data_DE.dta   : panel data for Germany 

Both files must be in the 'data/' sub-directory, or update the paths below.

Output
------
All tables are saved to the 'output/tables/' sub-directory (created automatically).
"""

import os
import pandas as pd
from scipy import stats

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
DATA_DIR   = 'data/'
OUTPUT_DIR = os.path.join('output', 'tables')
os.makedirs(OUTPUT_DIR, exist_ok=True)

NORDLINK_DATE = pd.Timestamp('2020-12-09')


# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
df_no2 = pd.read_stata(os.path.join(DATA_DIR, 'data_NO2.dta'))
df_no2['datetime'] = pd.to_datetime(df_no2['datetime'])

df_de = pd.read_stata(os.path.join(DATA_DIR, 'data_DE.dta'))
df_de['datetime'] = pd.to_datetime(df_de['datetime'])

# Split into before / after NordLink
no2_before = df_no2[df_no2['nordlink'] == 0]
no2_after  = df_no2[df_no2['nordlink'] == 1]
de_before  = df_de[df_de['nordlink'] == 0]
de_after   = df_de[df_de['nordlink'] == 1]


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

def price_stats(series):
    """Return the six statistics used in Table 1 for a price series."""
    return pd.Series({
        'Mean':     series.mean(),
        'Min':      series.min(),
        'Max':      series.max(),
        'Std. dev.': series.std(),
        'Skewness': stats.skew(series.dropna()),
        'Kurtosis': stats.kurtosis(series.dropna(), fisher=False),  # Pearson (normal=3)
    })

def mean_std(series):
    """Return mean with std dev in parentheses as a formatted string."""
    return f'{series.mean():.1f} ({series.std():.2f})'


# ---------------------------------------------------------------------------
# Table 1 -- Descriptive statistics for the day-ahead price
# ---------------------------------------------------------------------------

periods = {
    f'Before NordLink (n = {len(no2_before):,})': (no2_before['price'], de_before['price']),
    f'After NordLink (n = {len(no2_after):,})':   (no2_after['price'],  de_after['price']),
    f'Full sample (n = {len(df_no2):,})':          (df_no2['price'],     df_de['price']),
}

rows = []
for period_label, (no2_series, de_series) in periods.items():
    for zone_label, series in [('NO2', no2_series), ('Germany', de_series)]:
        s = price_stats(series)
        s.name = (period_label, zone_label)
        rows.append(s)

tab1 = pd.DataFrame(rows)
tab1.index = pd.MultiIndex.from_tuples(tab1.index)
tab1 = tab1.round(2)

# Format: integers for N in the period label, two decimals elsewhere
tab1_latex = tab1.to_latex(
    multirow=True,
    multicolumn=True,
    na_rep='--',
    float_format='%.2f',
    caption=(
        'Descriptive statistics for the day-ahead electricity price (EUR/MWh) '
        'in NO2 and Germany. NordLink opened on December 9, 2020.'
    ),
    label='tab:stats_price',
    position='h',
)

out = os.path.join(OUTPUT_DIR, 'tab01_stats_price.tex')
with open(out, 'w') as f:
    f.write(tab1_latex)
print(f'Saved: {out}')


# ---------------------------------------------------------------------------
# Appendix Table A2 -- Mean values and standard deviations of all variables
# ---------------------------------------------------------------------------

col_labels = [
    f'Before NordLink\n(n = {len(no2_before):,})',
    f'After NordLink\n(n = {len(no2_after):,})',
    f'Full sample\n(n = {len(df_no2):,})',
]

def build_panel(before_df, after_df, full_df, variables):
    """
    Build a panel of rows with 'Mean (Std. dev.)' strings for each variable
    across the three periods.
    """
    rows = {}
    for var_label, col in variables:
        rows[var_label] = [
            mean_std(before_df[col]),
            mean_std(after_df[col]),
            mean_std(full_df[col]),
        ]
    return pd.DataFrame(rows, index=col_labels).T

# Panel A: NO2
no2_vars = [
    ('Price (EUR/MWh)',  'price'),
    ('Load (GWh)',       'load'),
    ('Wind (GWh)',       'wind'),
    ('Reservoir (\\%)',    'reservoir'),
]
panel_no2 = build_panel(no2_before, no2_after, df_no2, no2_vars)

# Panel B: Germany
de_vars = [
    ('Price (EUR/MWh)', 'price'),
    ('Load (GWh)',      'load'),
    ('Wind (GWh)',      'wind'),
    ('Solar (GWh)',     'solar'),
]
panel_de = build_panel(de_before, de_after, df_de, de_vars)

# Panel C: European prices (gas and EUA are common to both datasets)
# Use df_no2 for all three since gas/eua are daily and identical across zones
euro_vars = [
    ('Gas (EUR/MWh)',    'gas'),
    ('EUA (EUR/tCO2)', 'eua'),
]
panel_euro = build_panel(no2_before, no2_after, df_no2, euro_vars)

n_cols = len(col_labels)
empty_row = pd.DataFrame([[''] * n_cols], columns=col_labels)

def with_header(panel_df, header_label):
    """Prepend a blank separator row whose index cell contains the panel header."""
    header = empty_row.copy()
    header.index = [f'\\textit{{{header_label}}}']
    return pd.concat([header, panel_df])

tabA2 = pd.concat([
    with_header(panel_no2,  'Panel A: NO2'),
    with_header(panel_de,   'Panel B: Germany'),
    with_header(panel_euro, 'Panel C: European prices'),
])

tabA2_latex = tabA2.to_latex(
    na_rep='--',
    caption=(
        'Mean values and standard deviations (in parentheses) of the day-ahead price '
        'and price fundamentals. NordLink opened on December 9, 2020.'
    ),
    label='tab:mean_values',
    position='h',
)

out = os.path.join(OUTPUT_DIR, 'tabA2_mean_values.tex')
with open(out, 'w') as f:
    f.write(tabA2_latex)
print(f'Saved: {out}')


print('\nDone. All available tables saved to:', OUTPUT_DIR)