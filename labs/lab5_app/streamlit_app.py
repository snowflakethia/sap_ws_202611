"""Supply Chain Risk Dashboard - Lab 5 reference app (Streamlit in Snowflake).

Reads 4 SAP data products plus the GNN demo schema, read-only. All data is synthetic, for demonstration only.
"""
import json

import altair as alt
import pandas as pd
import streamlit as st

st.set_page_config(page_title="Supply Chain Risk Dashboard", layout="wide")
# Works on both runtimes: st.connection on the container runtime, get_active_session on the warehouse runtime.
try:
    session = st.connection("snowflake").session()
except Exception:
    from snowflake.snowpark.context import get_active_session
    session = get_active_session()

DEMO = "DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK"
VENDORS = 'S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"'
MATERIALS = 'S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials"'
POS = 'S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders"'
BOM = 'S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials"'
SEARCH_SERVICE = f"{DEMO}.CONTRACT_SEARCH_SERVICE"
SEMANTIC_VIEW = f"{DEMO}.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW"

COUNTRY_COORDS = {
    "AUS": ("Australia", -25.3, 133.8), "CHL": ("Chile", -35.7, -71.5), "CHN": ("China", 35.9, 104.2),
    "COD": ("DR Congo", -4.0, 21.8), "DEU": ("Germany", 51.2, 10.4), "JPN": ("Japan", 36.2, 138.3),
    "KOR": ("South Korea", 35.9, 127.8), "MEX": ("Mexico", 23.6, -102.6), "USA": ("United States", 37.1, -95.7),
}
RISK_COLORS = alt.Scale(domain=["CRITICAL", "HIGH", "MEDIUM", "LOW"],
                        range=["#d62728", "#ff7f0e", "#e7ba52", "#2ca02c"])


@st.cache_data(ttl=600)
def q(sql: str) -> pd.DataFrame:
    return session.sql(sql).to_pandas()


def disclaimer():
    st.warning("**Synthetic data, for demonstration only.** Company names are used for illustration; vendors, "
               "orders, contracts, risk scores and predicted links are invented and describe no real company.")


def money(x: float) -> str:
    return f"${x / 1e6:,.1f}M"


# ---------------------------------------------------------------- shared data
@st.cache_data(ttl=600)
def supplier_spend() -> pd.DataFrame:
    return q(f"""
        SELECT s.VENDOR_ID, s.VENDOR_NAME, s.COUNTRY_CODE, s.TIER, s.REGION_RISK, s.GNN_RISK_SCORE,
               s.RISK_CATEGORY, s.CONFIDENCE, v.FINANCIAL_HEALTH_SCORE, v.CITY,
               COALESCE(SUM(p.QUANTITY * p.UNIT_PRICE), 0) AS SPEND,
               COUNT_IF(p.STATUS = 'OPEN') AS OPEN_POS
        FROM {DEMO}.VW_SUPPLIER_RISK s
        JOIN {VENDORS} v ON v.VENDOR_ID = s.VENDOR_ID
        LEFT JOIN {POS} p ON p.VENDOR_ID = s.VENDOR_ID
        GROUP BY ALL""")


PAGES = ["Executive overview", "Supplier risk explorer", "Hidden Tier 2 dependencies",
         "Materials & BOM exposure", "Contracts", "Business architecture", "Technical architecture"]
page = st.sidebar.radio("Dashboard", PAGES)
st.sidebar.caption("Data: 4 SAP data products + GNN outputs + external signals + contracts, on Snowflake.")

st.title("Supply Chain Risk Dashboard")
disclaimer()

# ---------------------------------------------------------------- 1. Executive overview
if page == "Executive overview":
    df = supplier_spend()
    total = df["SPEND"].sum()
    at_risk = df.loc[df["RISK_CATEGORY"].isin(["CRITICAL", "HIGH"]), "SPEND"].sum()
    bott = q(f"SELECT COUNT(*) AS N FROM {DEMO}.BOTTLENECKS_PREDICTIONS "
             f"WHERE MITIGATION_STATUS = 'UNMITIGATED' AND DEPENDENT_COUNT >= 10")["N"].iloc[0]
    single = q(f"SELECT COUNT(*) AS N FROM {DEMO}.VW_MATERIAL_RISK "
               f"WHERE NUM_SUPPLIERS <= 1 AND CRITICALITY_SCORE >= 0.8")["N"].iloc[0]

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total PO spend (SAP)", money(total))
    c2.metric("Spend at risk (HIGH + CRITICAL)", money(at_risk), f"{at_risk / total:.0%} of spend", delta_color="inverse")
    c3.metric("Unmitigated Tier 2 bottlenecks", int(bott), "10+ dependent suppliers each", delta_color="off")
    c4.metric("Critical materials, 0-1 supplier", int(single), "single point of failure", delta_color="off")

    # Semantic view: the same trusted definitions the Cortex Agent uses
    sv = q(f"""SELECT RISK_CATEGORY, COUNT(*) AS SUPPLIERS FROM SEMANTIC_VIEW({SEMANTIC_VIEW}
               DIMENSIONS VW_SUPPLIER_RISK.VENDOR_ID, VW_SUPPLIER_RISK.RISK_CATEGORY) GROUP BY 1""")
    left, right = st.columns(2)
    with left:
        st.subheader("Suppliers by GNN risk category")
        st.caption("Queried through the semantic view `SUPPLY_CHAIN_RISK_SEMANTIC_VIEW`.")
        st.altair_chart(alt.Chart(sv).mark_bar().encode(
            x=alt.X("RISK_CATEGORY:N", sort=["CRITICAL", "HIGH", "MEDIUM", "LOW"], title=None),
            y=alt.Y("SUPPLIERS:Q", title="Suppliers"),
            color=alt.Color("RISK_CATEGORY:N", scale=RISK_COLORS, legend=None)), use_container_width=True)
    with right:
        st.subheader("Spend by risk category")
        by_cat = df.groupby("RISK_CATEGORY", as_index=False)["SPEND"].sum()
        st.altair_chart(alt.Chart(by_cat).mark_arc(innerRadius=60).encode(
            theta="SPEND:Q", color=alt.Color("RISK_CATEGORY:N", scale=RISK_COLORS),
            tooltip=["RISK_CATEGORY", alt.Tooltip("SPEND:Q", format="$,.0f")]), use_container_width=True)

    st.subheader("Top actions")
    top = df[df["RISK_CATEGORY"].isin(["CRITICAL", "HIGH"])].sort_values("GNN_RISK_SCORE", ascending=False)
    for _, r in top.head(5).iterrows():
        st.markdown(f"- **{r.VENDOR_NAME}** ({r.COUNTRY_CODE}, {r.RISK_CATEGORY}, GNN {r.GNN_RISK_SCORE:.2f}): "
                    f"{money(r.SPEND)} spend, {int(r.OPEN_POS)} open POs. Qualify a second source and review the contract.")

# ---------------------------------------------------------------- 2. Supplier risk explorer
elif page == "Supplier risk explorer":
    df = supplier_spend()
    f1, f2, f3 = st.columns(3)
    countries = f1.multiselect("Country", sorted(df["COUNTRY_CODE"].unique()))
    tiers = f2.multiselect("Tier", sorted(df["TIER"].dropna().unique()))
    cats = f3.multiselect("Risk category", ["CRITICAL", "HIGH", "MEDIUM", "LOW"])
    if countries:
        df = df[df["COUNTRY_CODE"].isin(countries)]
    if tiers:
        df = df[df["TIER"].isin(tiers)]
    if cats:
        df = df[df["RISK_CATEGORY"].isin(cats)]

    by_country = df.groupby("COUNTRY_CODE", as_index=False).agg(
        SUPPLIERS=("VENDOR_ID", "count"), AVG_RISK=("GNN_RISK_SCORE", "mean"), SPEND=("SPEND", "sum"))
    by_country["COUNTRY"] = by_country["COUNTRY_CODE"].map(lambda c: COUNTRY_COORDS.get(c, (c, 0, 0))[0])
    by_country["LAT"] = by_country["COUNTRY_CODE"].map(lambda c: COUNTRY_COORDS.get(c, (c, 0, 0))[1])
    by_country["LON"] = by_country["COUNTRY_CODE"].map(lambda c: COUNTRY_COORDS.get(c, (c, 0, 0))[2])

    left, right = st.columns([3, 2])
    with left:
        st.subheader("Where the risk sits")
        st.map(by_country.rename(columns={"LAT": "lat", "LON": "lon"}), size="SPEND" if len(by_country) else None)
    with right:
        st.subheader("Average GNN risk by country")
        st.altair_chart(alt.Chart(by_country).mark_bar().encode(
            x=alt.X("AVG_RISK:Q", title="Avg GNN risk"), y=alt.Y("COUNTRY:N", sort="-x", title=None),
            tooltip=["COUNTRY", "SUPPLIERS", alt.Tooltip("SPEND:Q", format="$,.0f")]), use_container_width=True)

    st.subheader("SAP financial health vs GNN risk")
    st.caption("SAP tells you how healthy a supplier is; the GNN tells you how exposed it is through the network.")
    st.altair_chart(alt.Chart(df).mark_circle().encode(
        x=alt.X("FINANCIAL_HEALTH_SCORE:Q", title="SAP financial health"),
        y=alt.Y("GNN_RISK_SCORE:Q", title="GNN risk score"), size="SPEND:Q",
        color=alt.Color("RISK_CATEGORY:N", scale=RISK_COLORS),
        tooltip=["VENDOR_NAME", "COUNTRY_CODE", "RISK_CATEGORY", alt.Tooltip("SPEND:Q", format="$,.0f")]),
        use_container_width=True)
    st.dataframe(df.sort_values("GNN_RISK_SCORE", ascending=False), use_container_width=True, hide_index=True)

# ---------------------------------------------------------------- 3. Hidden Tier 2 dependencies
elif page == "Hidden Tier 2 dependencies":
    st.caption("Tier 2 suppliers don't appear in the SAP vendor master. The GNN predicts them from trade data.")
    min_p = st.slider("Minimum link probability", 0.5, 0.9, 0.55, 0.01)
    links = q(f"SELECT SOURCE_NAME, TARGET_NAME, PROBABILITY, EVIDENCE_STRENGTH FROM {DEMO}.VW_HIDDEN_DEPENDENCIES")
    links = links[links["PROBABILITY"] >= min_p]
    st.metric("Predicted hidden links at this threshold", len(links))
    if len(links):
        dot = ["digraph G { rankdir=LR; node [shape=box, style=rounded, fontsize=10];"]
        for s in links["SOURCE_NAME"].unique():
            dot.append(f'"{s}" [color="#d62728"];')
        for _, r in links.iterrows():
            dot.append(f'"{r.SOURCE_NAME}" -> "{r.TARGET_NAME}" [label="{r.PROBABILITY:.2f}", fontsize=8];')
        dot.append("}")
        st.graphviz_chart("\n".join(dot), use_container_width=True)
    st.subheader("Tier 2 bottlenecks (one failure, many suppliers affected)")
    bott = q(f"""SELECT NODE_ID AS EXTERNAL_SUPPLIER, DEPENDENT_COUNT, IMPACT_SCORE, MITIGATION_STATUS
                 FROM {DEMO}.BOTTLENECKS_PREDICTIONS ORDER BY DEPENDENT_COUNT DESC""")
    st.altair_chart(alt.Chart(bott).mark_bar(color="#d62728").encode(
        x=alt.X("DEPENDENT_COUNT:Q", title="Dependent SAP suppliers"),
        y=alt.Y("EXTERNAL_SUPPLIER:N", sort="-x", title=None)), use_container_width=True)
    st.dataframe(bott, use_container_width=True, hide_index=True)

# ---------------------------------------------------------------- 4. Materials & BOM exposure
elif page == "Materials & BOM exposure":
    mat = q(f"""SELECT r.MATERIAL_ID, r.DESCRIPTION, r.MATERIAL_GROUP, r.CRITICALITY_SCORE, r.GNN_RISK_SCORE,
                       r.NUM_SUPPLIERS, r.AVG_SUPPLIER_RISK, m.INVENTORY_DAYS
                FROM {DEMO}.VW_MATERIAL_RISK r JOIN {MATERIALS} m ON m.MATERIAL_ID = r.MATERIAL_ID""")
    st.subheader("Criticality vs inventory cover")
    st.caption("Top-left = critical parts with little stock: the first to stop a production line.")
    st.altair_chart(alt.Chart(mat).mark_circle(size=120).encode(
        x=alt.X("INVENTORY_DAYS:Q", title="Inventory days (SAP)"),
        y=alt.Y("CRITICALITY_SCORE:Q", title="Criticality (SAP)"),
        color=alt.Color("NUM_SUPPLIERS:Q", title="Suppliers", scale=alt.Scale(scheme="redyellowgreen")),
        tooltip=["MATERIAL_ID", "DESCRIPTION", "NUM_SUPPLIERS", "INVENTORY_DAYS"]), use_container_width=True)

    st.subheader("Bill of materials: which finished products are exposed?")
    bom = q(f"""SELECT b.PARENT_MATERIAL_ID, p.DESCRIPTION AS PARENT, b.CHILD_MATERIAL_ID, c.DESCRIPTION AS COMPONENT,
                       b.QUANTITY_PER_UNIT, r.NUM_SUPPLIERS, r.AVG_SUPPLIER_RISK, r.CRITICALITY_SCORE
                FROM {BOM} b
                JOIN {MATERIALS} p ON p.MATERIAL_ID = b.PARENT_MATERIAL_ID
                JOIN {MATERIALS} c ON c.MATERIAL_ID = b.CHILD_MATERIAL_ID
                LEFT JOIN {DEMO}.VW_MATERIAL_RISK r ON r.MATERIAL_ID = b.CHILD_MATERIAL_ID""")
    roll = bom.groupby("PARENT", as_index=False).agg(
        COMPONENTS=("CHILD_MATERIAL_ID", "count"), MAX_COMPONENT_RISK=("AVG_SUPPLIER_RISK", "max"),
        SINGLE_SOURCE_COMPONENTS=("NUM_SUPPLIERS", lambda s: int((s.fillna(0) <= 1).sum())))
    st.dataframe(roll.sort_values("MAX_COMPONENT_RISK", ascending=False), use_container_width=True, hide_index=True)
    with st.expander("Full BOM with component risk"):
        st.dataframe(bom, use_container_width=True, hide_index=True)

# ---------------------------------------------------------------- 5. Contracts
elif page == "Contracts":
    con = q(f"""SELECT CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME, SUPPLIER_COUNTRY, MATERIAL_TYPE,
                       CONTRACT_DATE, ANNUAL_VALUE_USD FROM {DEMO}.CUSTOMER_CONTRACTS ORDER BY CONTRACT_ID""")
    bott = q(f"SELECT NODE_ID FROM {DEMO}.BOTTLENECKS_PREDICTIONS")
    covered = [b for b in bott["NODE_ID"] if con["SUPPLIER_NAME"].str.contains(b, regex=False).any()]
    c1, c2, c3 = st.columns(3)
    c1.metric("Supplier contracts", len(con))
    c2.metric("Annual contract value", money(con["ANNUAL_VALUE_USD"].sum()))
    c3.metric("Tier 2 bottlenecks with a contract", f"{len(covered)} / {len(bott)}")
    st.dataframe(con, use_container_width=True, hide_index=True)

    st.subheader("Search the contracts (Cortex Search)")
    st.caption("Searches by meaning, not just keywords. Try: *can we walk away from the agreement early*")
    question = st.text_input("Ask about contract terms", "force majeure clause")
    if question:
        payload = json.dumps({"query": question, "columns": ["CONTRACT_ID", "CONTRACT_TITLE", "SUPPLIER_NAME",
                                                             "CONTRACT_TEXT"], "limit": 3})
        literal = payload.replace("\\", "\\\\").replace("'", "''")
        raw = session.sql(f"SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW('{SEARCH_SERVICE}', '{literal}') AS R").collect()[0]["R"]
        for hit in json.loads(raw).get("results", []):
            with st.expander(f"{hit['CONTRACT_ID']} - {hit['CONTRACT_TITLE']} ({hit['SUPPLIER_NAME']})"):
                st.text(hit["CONTRACT_TEXT"][:3000])

# ---------------------------------------------------------------- 6. Business architecture
elif page == "Business architecture":
    st.header("Business architecture: from system of record to decisions")
    st.graphviz_chart("""
    digraph B { rankdir=LR; node [shape=box, style="rounded,filled", fillcolor="#f5f7fa", fontsize=11];
      subgraph cluster_sap { label="SAP - system of record"; style=rounded;
        V [label="Vendors"]; M [label="Materials"]; P [label="Purchase orders"]; BM [label="Bill of materials"]; }
      BDC [label="SAP BDC Connect\\nzero-copy data products", fillcolor="#e8f0fe"];
      subgraph cluster_sf { label="Snowflake - system of context"; style=rounded;
        EXT [label="Trade data + regional risk"]; DOC [label="Supplier contracts"];
        GNN [label="GNN: risk scores +\\nhidden Tier 2 links"]; SEM [label="Semantic view:\\ntrusted definitions"]; }
      DEC [label="Decisions:\\nsecond source, buffer stock,\\ncontract review", fillcolor="#e6f4ea"];
      V -> BDC; M -> BDC; P -> BDC; BM -> BDC; BDC -> GNN; EXT -> GNN; GNN -> SEM; DOC -> SEM; SEM -> DEC;
      GNN -> BDC [style=dashed, label="publish back"]; }""", use_container_width=True)

    st.subheader("Which question, which data, which value")
    st.table(pd.DataFrame([
        ["How much of our spend is exposed?", "SAP purchase orders x GNN risk", "Spend at risk, prioritised mitigation budget"],
        ["Who are we really depending on?", "SAP vendors + trade data + GNN links", "Hidden Tier 2 bottlenecks found before they fail"],
        ["Which products stop if a part runs out?", "SAP BOM + materials + supplier risk", "Protected revenue, targeted buffer stock"],
        ["Are we covered contractually?", "Contracts (Cortex Search) + bottlenecks", "Faster legal review, fewer surprises"],
    ], columns=["Business question", "Data combined", "Business value"]))

    a, b = st.columns(2)
    with a:
        st.subheader("Why SAP data products matter")
        st.markdown("- **Governed and business-ready:** SAP semantics (vendors, materials, POs, BOM) kept intact.\n"
                    "- **Zero-copy through SAP BDC Connect:** no extracts, no second copy drifting out of date.\n"
                    "- **Same names in this lab and in production:** the app runs unchanged on live data products.")
    with b:
        st.subheader("Why the semantic layer matters")
        st.markdown("- **One definition of risk** shared by this dashboard, the Cortex Agent and analysts.\n"
                    "- **Verified queries** make the most important answers repeatable.\n"
                    "- **Business language** on top of SAP technical names, so AI and people read the data the same way.")
    st.info("**Design thinking:** this app was generated from one prompt. Use the same pattern in a workshop to turn "
            "an idea into a high-fidelity prototype on production-shaped data, test it with users the same day, and "
            "refine the prompt, all before committing to a production build.")

# ---------------------------------------------------------------- 7. Technical architecture
elif page == "Technical architecture":
    st.header("Technical architecture: how this app was built and what it runs on")
    st.graphviz_chart("""
    digraph T { rankdir=LR; node [shape=box, style="rounded,filled", fillcolor="#f5f7fa", fontsize=10];
      COCO [label="Cortex Code (CoCo)\\nin Snowsight\\none prompt", fillcolor="#fff4e5"];
      APP [label="Streamlit in Snowflake\\nSUPPLY_RISK_DASHBOARD", fillcolor="#e8f0fe"];
      WH [label="Warehouse\\nDEMO_19865_WH"];
      subgraph cluster_sap { label="SAP data product databases (4)"; style=rounded;
        S1 [label="S4_ZVENDORINFO"]; S2 [label="S4_ZMATERIALS"]; S3 [label="S4_ZPURCHASEORDERS"]; S4 [label="S4_ZBILLOFMATERIALS"]; }
      subgraph cluster_demo { label="DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK"; style=rounded;
        T [label="External tables\\ntrade, regions, contracts"]; G [label="GNN outputs\\nscores, links, bottlenecks"];
        VW [label="4 analytic views"]; SV [label="Semantic view"]; CS [label="Cortex Search service"]; AG [label="Cortex Agent"]; }
      SPCS [label="GNN training\\nSnowpark Container Services", fillcolor="#e6f4ea"];
      COCO -> APP [label="generates + deploys"]; APP -> WH;
      APP -> S1; APP -> S2; APP -> S3; APP -> S4; APP -> VW; APP -> SV; APP -> CS;
      S1 -> SPCS; S3 -> SPCS; T -> SPCS; SPCS -> G; G -> VW; VW -> SV; T -> CS; SV -> AG; CS -> AG; }""",
        use_container_width=True)

    st.subheader("Objects this app depends on")
    objs = q("""SELECT 'Analytic views' AS KIND, COUNT(*)::VARCHAR AS FOUND FROM DEMO_19865_DB.INFORMATION_SCHEMA.VIEWS
                   WHERE TABLE_SCHEMA = 'GNN_SUPPLY_CHAIN_RISK' AND TABLE_NAME LIKE 'VW_%'
                 UNION ALL SELECT 'Demo tables', COUNT(*)::VARCHAR FROM DEMO_19865_DB.INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = 'GNN_SUPPLY_CHAIN_RISK' AND TABLE_TYPE = 'BASE TABLE'""")
    st.table(pd.DataFrame([
        ["SAP data products (4 databases)", "Vendors, materials, purchase orders, BOM", "Zero-copy sharing / catalog-linked databases"],
        ["Demo tables", f"{objs.loc[objs.KIND == 'Demo tables', 'FOUND'].iloc[0]} tables: trade, regions, contracts, GNN outputs", "Snowflake tables, cross-database joins"],
        ["Analytic views", f"{objs.loc[objs.KIND == 'Analytic views', 'FOUND'].iloc[0]} views joining SAP + GNN", "Views, RBAC"],
        ["Semantic view", "SUPPLY_CHAIN_RISK_SEMANTIC_VIEW", "Semantic views + verified queries"],
        ["Cortex Search", "CONTRACT_SEARCH_SERVICE", "Hybrid vector + keyword search, auto-refresh"],
        ["Cortex Agent", "GNN_SUPPLY_RISK_AGENT (Lab 2)", "Cortex Agents, cross-region inference"],
        ["GNN model", "PyTorch Geometric notebook (Lab 4)", "Snowpark Container Services, notebooks"],
        ["This app", "SUPPLY_RISK_DASHBOARD", "Streamlit in Snowflake, Cortex Code (CoCo)"],
    ], columns=["Component", "What it is", "Snowflake feature"]))

    st.subheader("How it was built")
    st.markdown("1. **One prompt in CoCo** (Snowsight) described the users, pages, data and rules.\n"
                "2. CoCo **explored the schemas, wrote and tested the SQL**, generated the Streamlit code and **deployed** it.\n"
                "3. The app runs **inside Snowflake** with the owner role `DEMO_19865_ROLE` and warehouse `DEMO_19865_WH`: "
                "no servers, no credentials, no data leaving the platform.\n"
                "4. Iterate with follow-up prompts; promote by pointing the same code at live SAP BDC data products.")
