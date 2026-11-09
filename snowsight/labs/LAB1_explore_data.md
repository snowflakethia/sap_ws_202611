# Lab 1 - Explore the data: find the supplier nobody told you about

> **Your SAP vendor master lists 50 suppliers. Two companies that aren't in it at all each sit behind 48 of them.**
> If *Tokyo Chemical Works* or *Bavaria Specialty Metals* stopped shipping, almost your entire supply base
> would feel it, and nothing in your ERP would have warned you. In this lab you'll find them yourself, using
> plain SQL over SAP data, external trade records and the output of a graph neural network.

**Time:** 15 minutes. **Before you start:** run `snowsight/08_readiness_check.sql`; it must say READY.

**What you'll learn**
- How SAP data products look in Snowflake, and why their names need quotes.
- How external data (bills of lading, regional risk) reveals what ERP data can't.
- How to read GNN results: risk scores, predicted hidden links and single points of failure.

---

## Set up your SQL file

1. In **Workspaces**, make sure the selector says **gnn_training**. Click **+ Add new > SQL File** and name it `lab1.sql`.
2. For each block below: paste it into `lab1.sql`, **select just those lines**, and press **Run**
   (Ctrl/Cmd + Enter). Each result appears in the results pane at the bottom.

```sql
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
```

**What it does:** sets your session context, meaning *who* you are, *what compute* runs your queries, and
*where* unqualified table names are looked up.
- `USE ROLE DEMO_19865_ROLE` switches to the course's project role, which owns the demo objects.
- `USE WAREHOUSE DEMO_19865_WH` picks the compute that runs the queries. A Small warehouse is plenty here.
- `USE SCHEMA ...` lets you write `REGIONS_EXTERNAL` instead of `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.REGIONS_EXTERNAL`.

**Why:** every query below depends on these three settings. If a later query says *"does not exist or not
authorized"*, run this block again.

---

## Step 1 - What SAP knows: the data products

```sql
SELECT * FROM "S4_ZVENDORINFO_DP_DELTA_SHARING_V1"."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors" LIMIT 10;
```

**What it does:** reads 10 rows from the SAP **vendor master** data product: supplier ID, name, country, city,
phone, tier and a financial health score.

**Why:** this is your *known* supply base, the suppliers SAP has purchase relationships with. Note the
**three-part name**:
- `S4_ZVENDORINFO_DP_DELTA_SHARING_V1` is the database (one per SAP data product).
- `"s4_zvendorinfo_dp_srv:v1"` is the schema (the SAP service and version).
- `"s4custom_vendors"` is the table.

SAP Business Data Cloud publishes the schema and table names in **lowercase**, so they must be in
**double quotes**. Without quotes, Snowflake converts names to uppercase and can't find them.

```sql
SELECT MATERIAL_GROUP, COUNT(*) AS MATERIALS
FROM "S4_ZMATERIALS_DP_DELTA_SHARING_V1"."s4_zmaterials_dp_srv:v1"."s4custom_materials"
GROUP BY MATERIAL_GROUP
ORDER BY MATERIAL_GROUP;
```

**What it does:** counts the materials in the SAP **material master**, grouped by material group:
- **RAW** - raw materials;
- **SEMI** - semi-finished parts;
- **FIN** - finished products.

**Why:** it shows the shape of the bill of materials. Many raw materials feed a few assemblies, which feed one
product. Risk on a single raw material can travel up that chain.

**Expected:** FIN **1**, RAW **20**, SEMI **5** (26 materials).

---

## Step 2 - What SAP doesn't know: external signals

```sql
SELECT REGION_CODE, REGION_NAME, BASE_RISK_SCORE
FROM REGIONS_EXTERNAL
ORDER BY BASE_RISK_SCORE DESC;
```

**What it does:** lists the 9 sourcing regions, highest base risk first (0 = low, 1 = high). The table also has
separate `GEOPOLITICAL_RISK`, `NATURAL_DISASTER_RISK` and `INFRASTRUCTURE_SCORE` columns; add them to the
`SELECT` if you want to see what drives a region's score.

**Why:** region data is one of the inputs the GNN notebook loads, and `VW_SUPPLIER_RISK` shows it next to each
supplier as `REGION_RISK`. Where a supplier operates is part of its risk.

**Expected:** 9 rows. **Australia 0.8** and **DR Congo 0.7** at the top.

```sql
SELECT SHIPPER_NAME, CONSIGNEE_NAME, HS_DESCRIPTION, SHIP_DATE
FROM TRADE_DATA_EXTERNAL
ORDER BY SHIP_DATE DESC
LIMIT 10;
```

**What it does:** shows recent **bills of lading**, the customs records of who shipped what to whom.
`HS_DESCRIPTION` is the product category from the international Harmonized System code.

**Why:** this is how you see *beyond Tier 1*. A shipper sending goods to **your** supplier is your Tier 2
supplier, even if you've never bought from it. The 150 records name **10** shippers, and **none** of them is in
the SAP vendor master. Their customers (the consignees) are **48** of your 50 SAP vendors.

---

## Step 3 - What the GNN found

```sql
SELECT * FROM VW_RISK_SUMMARY;
```

**What it does:** summarises the GNN's risk scores into two rows, **SUPPLIERS** and **PARTS**. It counts how
many fall into each risk category (CRITICAL, HIGH, MEDIUM, LOW) and gives the average score.

**Why:** it's the executive view. Out of 50 suppliers, how many need attention today?

**Expected:** SUPPLIERS: total **50**, critical **2**, high **4**. PARTS: total **26**, critical **0**.

```sql
SELECT VENDOR_NAME, COUNTRY_CODE, TIER,
       ROUND(GNN_RISK_SCORE, 4) AS GNN_RISK_SCORE, RISK_CATEGORY,
       TOTAL_ORDERS, ROUND(TOTAL_ORDER_VALUE) AS TOTAL_ORDER_VALUE
FROM VW_SUPPLIER_RISK
ORDER BY GNN_RISK_SCORE DESC NULLS LAST
LIMIT 6;
```

**What it does:** ranks suppliers by GNN risk score. `VW_SUPPLIER_RISK` joins three things:
- the **SAP vendor master** (name, country, tier);
- the **GNN score**;
- **SAP purchase orders** (order count and value).

`NULLS LAST` keeps suppliers without a score at the bottom.

**Why:** a risk score alone doesn't tell you what to act on. Putting risk next to *spend* tells you which risks
are expensive. A graph neural network scores each supplier using its **neighbours** in the supply network as well
as its own attributes. That's why connected suppliers can end up with similar scores.

**Expected:** **Albemarle Corp** and **Epsilon Tech** (AUS, CRITICAL, about 0.61), then 4 HIGH suppliers in COD.

```sql
SELECT SOURCE_NAME, TARGET_NAME, ROUND(PROBABILITY, 3) AS PROBABILITY, EVIDENCE_STRENGTH
FROM VW_HIDDEN_DEPENDENCIES
ORDER BY PROBABILITY DESC
LIMIT 10;
```

**What it does:** shows the **hidden links** the GNN predicted. Each row reads *SOURCE probably supplies TARGET*.
The view only keeps links with a probability of at least 0.5.

**Why:** this is *link prediction*, the GNN's main job here. It learned the patterns of known relationships
(purchase orders, bills of materials, shipments) and estimated which unrecorded relationships probably exist.

**Expected:** 26 links in total, all **MODERATE** evidence. The strongest is *Queensland Minerals -> BYD Battery*
(about 0.70).

```sql
SELECT NODE_ID AS COMPANY, NODE_TYPE, DEPENDENT_COUNT, DESCRIPTION
FROM BOTTLENECKS_PREDICTIONS
ORDER BY DEPENDENT_COUNT DESC
LIMIT 5;
```

**What it does:** lists the **single points of failure**: companies that many of your suppliers depend on.
`DEPENDENT_COUNT` is how many of your suppliers sit downstream of that company.

**Why:** this answers the opening question. A bottleneck isn't necessarily a risky supplier; it's a company
*everyone else* depends on.

**Expected:** **Tokyo Chemical Works** and **Bavaria Specialty Metals** (48 dependents each), then **Congo Cobalt
Mines** (47). All three are `EXTERNAL_SUPPLIER`: they came from trade data, not from SAP.

---

## Discuss
1. Australia has the highest regional risk (0.8), and both CRITICAL suppliers are Australian. How much of their
   score do you think comes from *where* they are, compared with *who they're connected to*?
2. The view shows only links with probability of at least 0.5, and there are 355 WEAK links below that. When
   would you want to see the weak ones too?
3. Tokyo Chemical Works isn't in your vendor master. Who in your organisation would need to know about it, and
   what could they do?

**Next:** [Lab 2 - Ask the agent](LAB2_ask_the_agent.md). You'll get the same insights by asking in plain English.
