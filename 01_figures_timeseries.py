"""
01_figures_timeseries.py
========================
Generates all time series figures for:

    Bjørndal, Bjørndal, Hovdahl & Tselika (2026)
    "European market integration and price convergence:
     A panel quantile regression analysis of NordLink"
    Energy Policy

Figures produced
----------------
Figure 1  : fig01_price_plot.png        -- Hourly day-ahead price, NO2 and Germany
Figure 2  : fig02_drivers.png           -- Gas price, EUA price, NO2 reservoir level
App. Fig A1 : figA1_fundamentals_no2.png -- Load and wind in NO2
App. Fig A2 : figA2_fundamentals_de.png  -- Load, wind and solar in Germany

Input data
----------
data_NO2.dta  : panel data for NO2  
data_DE.dta   : panel data for Germany 

Both files must be in the 'data/' sub-directory, or update the paths below.

Output
------
All figures are saved to the 'output/graphs/' sub-directory (created automatically).
"""

import os
import pandas as pd
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------
# Paths -- edit DATA_DIR if your .dta files live elsewhere
# ---------------------------------------------------------------------------
DATA_DIR   = 'data/'
OUTPUT_DIR = os.path.join('output', 'graphs')
os.makedirs(OUTPUT_DIR, exist_ok=True)

NORDLINK_DATE = pd.Timestamp('2020-12-09')


# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
df_no2 = pd.read_stata(os.path.join(DATA_DIR, 'data_NO2.dta'))
df_no2['datetime'] = pd.to_datetime(df_no2['datetime'])

df_de = pd.read_stata(os.path.join(DATA_DIR, 'data_DE.dta'))
df_de['datetime'] = pd.to_datetime(df_de['datetime'])


# ---------------------------------------------------------------------------
# Figure 1 -- Hourly day-ahead electricity price, NO2 and Germany
# ---------------------------------------------------------------------------
with plt.style.context('seaborn-v0_8-talk'):

    fig, ax = plt.subplots(nrows=2, sharey=True, figsize=(12, 8))

    df_no2.set_index('datetime')['price'].plot(ax=ax[0], xlabel='', lw=0.5)
    ax[0].set_title('(a) NO2')

    df_de.set_index('datetime')['price'].plot(ax=ax[1], xlabel='', lw=0.5)
    ax[1].set_title('(b) Germany')

    for a in ax:
        a.set_ylabel('EUR/MWh')
        a.grid()
        a.axvline(NORDLINK_DATE, color='black', ls='--')

    plt.subplots_adjust(hspace=0.35)

    out = os.path.join(OUTPUT_DIR, 'fig01_price_plot.png')
    plt.savefig(out, dpi=500, bbox_inches='tight')
    plt.close()
    print(f"Saved: {out}")


# ---------------------------------------------------------------------------
# Figure 2 -- Gas price, EUA price, and NO2 reservoir filling rate
# ---------------------------------------------------------------------------
with plt.style.context('seaborn-v0_8-talk'):

    fig, ax = plt.subplots(ncols=2, figsize=(18, 5))

    # Left panel: gas and EUA prices
    df_no2[['datetime', 'gas', 'eua']].set_index('datetime').plot(
        ax=ax[0], xlabel='', legend=True
    )
    ax[0].legend(['Gas price (EUR/MWh)', 'EUA price (EUR/tCO\u2082)'], loc='upper left')
    ax[0].set_title('European fuel and carbon prices')

    # Right panel: reservoir filling rate and historical median
    df_no2[['datetime', 'reservoir', 'resmedian']].set_index('datetime').plot(
        ax=ax[1], xlabel='', legend=True
    )
    ax[1].legend(['Filling rate (%)', 'Historical median (%)'])
    ax[1].set_title('NO2 water reservoirs')

    for a in ax:
        a.axvline(NORDLINK_DATE, color='black', ls='--')
        a.grid()

    plt.subplots_adjust(wspace=0.1, hspace=0.3)

    out = os.path.join(OUTPUT_DIR, 'fig02_drivers.png')
    plt.savefig(out, dpi=500, bbox_inches='tight')
    plt.close()
    print(f"Saved: {out}")


# ---------------------------------------------------------------------------
# Appendix Figure A1 -- Load and wind generation in NO2
# ---------------------------------------------------------------------------
with plt.style.context('seaborn-v0_8-talk'):

    fig, axes = plt.subplots(nrows=3, figsize=(12, 12))
    axes[-1].remove()  # NO2 has no solar; remove the third (empty) panel

    cols   = ['load', 'wind']
    titles = ['Load (GWh)', 'Wind (GWh)']

    for i, (col, title) in enumerate(zip(cols, titles)):
        df_no2.set_index('datetime')[col].plot(ax=axes[i], xlabel='', lw=0.5)
        axes[i].axvline(NORDLINK_DATE, color='black', ls='--')
        axes[i].set_title(title)
        axes[i].grid()

    plt.subplots_adjust(hspace=0.35)

    out = os.path.join(OUTPUT_DIR, 'figA1_fundamentals_no2.png')
    plt.savefig(out, dpi=500, bbox_inches='tight')
    plt.close()
    print(f"Saved: {out}")


# ---------------------------------------------------------------------------
# Appendix Figure A2 -- Load, wind and solar generation in Germany
# ---------------------------------------------------------------------------
with plt.style.context('seaborn-v0_8-talk'):

    fig, axes = plt.subplots(nrows=3, figsize=(12, 12))

    cols   = ['load', 'wind', 'solar']
    titles = ['Load (GWh)', 'Wind (GWh)', 'Solar (GWh)']

    for i, (col, title) in enumerate(zip(cols, titles)):
        df_de.set_index('datetime')[col].plot(ax=axes[i], xlabel='', lw=0.5)
        axes[i].axvline(NORDLINK_DATE, color='black', ls='--')
        axes[i].set_title(title)
        axes[i].grid()

    plt.subplots_adjust(hspace=0.35)

    out = os.path.join(OUTPUT_DIR, 'figA2_fundamentals_de.png')
    plt.savefig(out, dpi=500, bbox_inches='tight')
    plt.close()
    print(f"Saved: {out}")


print("\nDone. All available figures saved to:", OUTPUT_DIR)
