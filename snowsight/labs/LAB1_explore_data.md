# Lab 1 - Explore the data

**Goal:** understand the data behind the agent before you ask it anything.
**Time:** 15 minutes. **Before you start:** run `snowsight/08_readiness_check.sql`; it must say READY.

## Set up
1. In **Projects > Workspaces > gnn_training**, select **+ Add new > SQL File** and name it `lab1.sql`.
2. Paste each block below into `lab1.sql`. Select the lines, then press **Run** (Ctrl/Cmd + Enter).

```sql
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
```

## Step 1 - The SAP data products
These four tables are a snapshot of SAP S/4HANA data products. In the original demo they are live
SAP Business Data Cloud shares; here they have the same names.

```sql
SELECT * FROM "S4_ZVENDORINFO_DP_DELTA_SHARING_V1"."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors" LIMIT 10;

SELECT MATERIAL_GROUP, COUNT(*) AS MATERIALS
FROM "S4_ZMATERIALS_DP_DELTA_SHARING_V1"."s4_zmaterials_dp_srv:v1"."s4custom_materials"
GROUP BY 1 ORDER BY 1;
```

**Expected:** 10 vendors with ID, name, country and tier. Materials by group: **FIN 1, RAW 20, SEMI 5**.

> The schema and table names are lowercase and in double quotes. Without the quotes, Snowflake reads them
> as uppercase and won't find them.

## Step 2 - External signals

```sql
SELECT REGION_CODE, REGION_NAME, BASE_RISK_SCORE FROM REGIONS_EXTERNAL ORDER BY BASE_RISK_SCORE DESC;
SELECT SHIPPER_NAME, CONSIGNEE_NAME, HS_DESCRIPTION, SHIP_DATE FROM TRADE_DATA_EXTERNAL LIMIT 10;
```

**Expected:** **9** regions, ordered by risk. The trade data (bills of lading) shows shipments between
companies, including Tier 2 suppliers that don't appear in the SAP vendor list.

## Step 3 - The GNN results

```sql
SELECT * FROM VW_RISK_SUMMARY;

SELECT VENDOR_NAME, COUNTRY_CODE, TIER, ROUND(GNN_RISK_SCORE, 4) AS GNN_RISK_SCORE, RISK_CATEGORY
FROM VW_SUPPLIER_RISK
ORDER BY GNN_RISK_SCORE DESC NULLS LAST LIMIT 6;

SELECT SOURCE_NAME, TARGET_NAME, PROBABILITY, EVIDENCE_STRENGTH FROM VW_HIDDEN_DEPENDENCIES LIMIT 10;
```

**Expected:**
- `VW_RISK_SUMMARY`: 2 rows. SUPPLIERS has total **50**, critical **2**, high **4**. PARTS has total **26**.
- Top suppliers: **Albemarle Corp** and **Epsilon Tech** (AUS, CRITICAL, about 0.61), then 4 HIGH suppliers in COD.
- `VW_HIDDEN_DEPENDENCIES`: predicted links with probability of at least 0.5 (26 in total).

## Discuss
1. The 2 CRITICAL suppliers are in Australia, but the 4 HIGH ones are all in COD. What could explain that?
   (Hint: compare `REGIONS_EXTERNAL.BASE_RISK_SCORE`.)
2. Why does `VW_HIDDEN_DEPENDENCIES` show only links with probability of at least 0.5?
