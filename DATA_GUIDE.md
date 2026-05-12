# Data Guide

This document describes the data used in:

> Bjørndal, Bjørndal, Hovdahl & Tselika (2026). "European market integration and price convergence: A panel quantile regression analysis of NordLink." *Energy Policy.*

The replication package does not include the raw data or the final datasets. This guide explains what data to collect, where to find it, and how the final datasets were constructed. Most data are freely available; the only exception is the gas and EUA price data, which require a paid Bloomberg subscription (see Section 4).

---

## 1. Sample period and scope

The analysis covers hourly electricity prices and market fundamentals for two bidding zones:

- **NO2**: southern Norway (Kristiansand area)
- **DE_LU**: Germany-Luxembourg (referred to as "Germany" throughout the paper)

The sample runs from **October 1, 2018** to **September 30, 2021** (26,304 hourly observations per zone). The start date coincides with the splitting of the German-Austrian-Luxembourg (DE_AT_LU) bidding zone into DE_LU and AT in September, 2018. The end date coincides with the opening of NorthSeaLink (a new cable from NO2 to the UK) in October, 2021. NordLink itself opened on **December 9, 2020**, which is the treatment date in the analysis.

---

## 2. ENTSO-E Transparency Platform

Four series are downloaded from the [ENTSO-E Transparency Platform](https://transparency.entsoe.eu). All series are available free of charge after registering for an account. Select bidding zones **NO2** and **DE_LU** and the date range October 1, 2018 to September 30, 2021.

### 2.1 Day-ahead electricity price

- **Category**: *Day-ahead Prices* (12.1.D)
- **Resolution**: hourly
- **Unit**: EUR/MWh
- **Variable in final dataset**: `price`

### 2.2 Day-ahead total load forecast

- **Category**: *Day-ahead Total Load Forecast* (6.1.B)
- **Resolution**: hourly for NO2; 15-minute intervals for DE_LU
- **Unit**: MW → convert to GWh
- **Variable in final dataset**: `load`

The German series is reported at 15-minute resolution and is aggregated to hourly by averaging. Germany has some hours with missing forecast values; for these, the missing forecast is replaced with the corresponding value from the *Actual Total Load* series (6.1.A).

### 2.3 Day-ahead wind and solar generation forecast

- **Category**: *Day-ahead Generation Forecasts for Wind and Solar* (14.1.D)
- **Resolution**: hourly for NO2; 15-minute intervals for DE_LU
- **Unit**: MW → convert to GWh
- **Variables in final dataset**: `wind`, `solar`

The data contain separate series for offshore and onshore wind, which are summed to obtain total wind generation. The German series is aggregated from 15-minute to hourly resolution by averaging. NO2 has no solar generation in the sample, so `solar` is only included in the German dataset.

---

## 3. NVE reservoir filling rate

Weekly data on the aggregated filling rate of water reservoirs in NO2 are available from the Norwegian Water Resources and Energy Directorate (NVE):

- **URL**: https://www.nve.no/energi/analyser-og-statistikk/magasinstatistikk/
- **Unit**: percentage of full capacity (%)
- **Variables in final dataset**: `reservoir`, `resmedian`, `belowmedian`

The NVE file contains both the observed weekly filling rate and a historical median filling rate calculated for each week of the year based on the preceding 20 years. The weekly series is linearly interpolated to a daily frequency for use in the model.

The below-median reservoir dummy used in the baseline model is:

```         
belowmedian = 1  if  reservoir < resmedian
belowmedian = 0  otherwise
```

The actual filling rate (`reservoir`) is used directly in robustness check 3 as an alternative to the dummy (see `06_robustness.do`).

---

## 4. Bloomberg fuel and carbon prices (paid subscription required)

The gas and EUA price series require access to Bloomberg and cannot be redistributed. Users must download them independently.

| Variable | Bloomberg ticker | Description | Unit |
|------------------|------------------|------------------|------------------|
| `gas` | `EGTHDAHD BCFV Index` | Physical forward price for natural gas delivered to Germany | EUR/MWh |
| `eua` | `DBRST3PA Index` | EU Emissions Trading System allowance price | EUR/tCO2 |
| `coal` | `API21MON OECM Index` | Coal price (robustness check only) | USD/tonne |

All three series are reported at daily frequency on trading days only. Missing values on weekends and public holidays are forward-filled using the most recently available price, representing the latest information available to market participants when bids were submitted.

All three series enter the model with a **one-day lag** (`gaslag1`, `eualag1`, `coallag1`).

---

## 5. Final datasets

Three Stata datasets are used in the analysis, all structured as panels with **hours (1-24) as the cross-sectional unit** and **days as the time dimension**. In Stata, the panel is declared as:

``` stata
encode date, gen(date1)
xtset hour date1
```

### `data_NO2.dta`

One row per hour per day (26,304 observations).

| Variable      | Description                                 | Unit       |
|---------------|---------------------------------------------|------------|
| `datetime`    | Hourly timestamp                            | UTC        |
| `date`        | Date string                                 | YYYY-MM-DD |
| `hour`        | Hour of day                                 | 1-24       |
| `price`       | Day-ahead electricity price                 | EUR/MWh    |
| `load`        | Day-ahead total load forecast               | GWh        |
| `wind`        | Day-ahead wind generation forecast          | GWh        |
| `reservoir`   | Aggregated filling rate of water reservoirs | \%         |
| `resmedian`   | Historical median filling rate              | \%         |
| `belowmedian` | 1 if reservoir below median, 0 otherwise    | \-         |
| `gas`         | Natural gas price *(Bloomberg)*             | EUR/MWh    |
| `eua`         | EUA carbon permit price *(Bloomberg)*       | EUR/tCO2   |
| `coal`        | Coal price *(Bloomberg, robustness only)*   | USD/tonne  |
| `gaslag1`     | Gas price, one-day lag *(Bloomberg)*        | EUR/MWh    |
| `eualag1`     | EUA price, one-day lag *(Bloomberg)*        | EUR/tCO2   |
| `coallag1`    | Coal price, one-day lag *(Bloomberg)*       | USD/tonne  |
| `pricelag1`   | Day-ahead price, one-day lag                | EUR/MWh    |
| `pricelag7`   | Day-ahead price, seven-day lag              | EUR/MWh    |
| `nordlink`    | 1 from December 9, 2020 onwards, 0 before   | \-         |
| `weekend`     | 1 for Saturday and Sunday, 0 otherwise      | \-         |
| `month`       | Month                                       | 1-12       |
| `year`        | Year                                        | \-         |

### `data_DE.dta`

Same structure as `data_NO2.dta`, with `solar` (GWh) included and `reservoir`, `resmedian`, and `belowmedian` excluded.

### `data_spread.dta`

Constructed by merging `data_NO2.dta` and `data_DE.dta` on `datetime`. Contains the following cross-zonal variables in addition to the shared variables (`nordlink`, `weekend`, `month`, `hour`, `date`):

| Variable | Description | Unit |
|------------------------|------------------------|------------------------|
| `price_diff` | Germany minus NO2 day-ahead price | EUR/MWh |
| `load_diff` | Germany minus NO2 load forecast | GWh |
| `wind_diff` | Germany minus NO2 wind generation forecast | GWh |
| `solar` | Germany solar generation forecast (levels) | GWh |
| `belowmedian` | NO2 below-median reservoir dummy (levels) | \- |
| `gaslag1` | Lagged gas price, common to both zones *(Bloomberg)* | EUR/MWh |
| `eualag1` | Lagged EUA price, common to both zones *(Bloomberg)* | EUR/tCO2 |
| `pricelag1_diff` | One-day lag of `price_diff` | EUR/MWh |
