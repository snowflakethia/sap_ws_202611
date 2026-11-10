# Lab 1 - Explore the data

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

**Goal:** understand the data behind the agent before you start asking it questions.
**Time:** 15 minutes. **Where:** Snowsight > Projects > Workspaces > `DEMO_19865`, or any SQL worksheet.

Set your context first:

```sql
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
```

> [!TIP]
> **Key takeaway: SAP shows you your Tier 1 suppliers; external trade data plus a GNN reveal the hidden Tier 2 links behind them.**
> - The SAP data products are queried **in place, under their SAP names** (quoted, lowercase), exactly as SAP BDC publishes them.
> - The trade data (bills of lading) names suppliers that **aren't in the SAP vendor master at all**.
> - The GNN turns SAP + external signals into **risk scores and predicted links**: 2 CRITICAL suppliers, both in Australia.

## 1. The SAP data products (snapshot)

The four SAP S/4HANA data products are read-only tables. In the original environment they are
live SAP Business Data Cloud shares; here they are a snapshot with the same names.

```sql
SELECT * FROM "S4_ZVENDORINFO_DP_DELTA_SHARING_V1"."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors" LIMIT 10;
SELECT MATERIAL_GROUP, COUNT(*) FROM "S4_ZMATERIALS_DP_DELTA_SHARING_V1"."s4_zmaterials_dp_srv:v1"."s4custom_materials" GROUP BY 1;
```

Expected: 50 vendors in total; 26 materials: RAW 20, SEMI 5, FIN 1.

Note the quoted, lowercase schema and table names. Snowflake identifiers are case-sensitive
when quoted, so `s4custom_vendors` without quotes will fail.

## 2. External signals

```sql
SELECT * FROM REGIONS_EXTERNAL ORDER BY BASE_RISK_SCORE DESC;
SELECT SHIPPER_NAME, CONSIGNEE_NAME, HS_DESCRIPTION, SHIP_DATE FROM TRADE_DATA_EXTERNAL LIMIT 10;
```

Expected: 9 regions and 150 bills of lading. The trade data reveals Tier 2 suppliers that are
not in the SAP vendor master.

## 3. The GNN outputs

```sql
SELECT * FROM VW_RISK_SUMMARY;
SELECT VENDOR_NAME, COUNTRY_CODE, GNN_RISK_SCORE, RISK_CATEGORY FROM VW_SUPPLIER_RISK
ORDER BY GNN_RISK_SCORE DESC NULLS LAST LIMIT 10;
SELECT SOURCE_NAME, TARGET_NAME, PROBABILITY, EVIDENCE_STRENGTH FROM VW_HIDDEN_DEPENDENCIES LIMIT 10;
```

Expected: `VW_RISK_SUMMARY` has 2 rows (SUPPLIERS 50, PARTS 26). 2 suppliers are CRITICAL
(Albemarle Corp and Epsilon Tech, both AUS) and 4 are HIGH (all COD). `VW_HIDDEN_DEPENDENCIES`
has 26 predicted links with probability of at least 0.5.

## Questions to discuss
1. Which country do the CRITICAL suppliers come from, and does the region risk explain it?
2. Why does `VW_HIDDEN_DEPENDENCIES` only show links with probability >= 0.5?
