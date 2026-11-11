# The labs: from SAP data to an AI agent and a business-ready app

> [!CAUTION]
> **Disclaimer:** all data in these labs is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

**The story across the five labs:** a manufacturer of EV battery packs runs on SAP S/4HANA. SAP knows its 50 direct
(Tier 1) suppliers, but not who *they* buy from, and that's where the next disruption will come from. Through
**SAP Business Data Cloud (BDC)**, the SAP data products land in Snowflake without copying. Snowflake adds the
context SAP doesn't have (trade data, regional risk, supplier contracts, a graph neural network and Cortex AI) and
turns it into answers and an app the business can use.

**SAP is the system of record. Snowflake is the system of context. SAP BDC Connect bridges the two.**

**Before you start any lab:** finish the setup in the main [README](../README.md#setup-browser-only-about-30-minutes)
until `snowsight/08_readiness_check.sql` says **READY**. Every lab only needs that setup; none of them depends on
another lab.

---

## The five labs at a glance

| Lab | Time | You will | Key takeaway |
| --- | --- | --- | --- |
| [1. Explore the data](lab1_explore_data.md) | 15 min | Query SAP data products next to external trade data and the GNN's risk scores | SAP shows you your Tier 1 suppliers; external trade data plus a GNN reveal the hidden Tier 2 links behind them |
| [2. Ask the agent](lab2_ask_the_agent.md) **(recommended)** | 25 min | Ask a Cortex Agent 5 questions, then audit every answer in its traces | One agent answers questions over numbers and contracts together, and every answer can be checked |
| [3. Build your own agent](lab3_build_your_own_agent.md) | 20 min | Build an agent in Agent Studio and compare it with the tuned one | Same tools, no orchestration instructions, a weaker agent: the instructions are what make it production-ready |
| [4. Retrain the GNN](lab4_optional_retrain_gnn.md) (optional) | 45-60 min | Run the graph neural network notebook on Snowpark Container Services | The risk scores aren't magic: they come from a GNN you can retrain on governed Snowflake data, without exporting it |
| [5. Build a dashboard with one prompt](lab5_dashboard_with_coco.md) **(recommended)** | 45-60 min | Turn everything into a 2-page Streamlit app with one Cortex Code (CoCo) prompt | One prompt turns SAP data products into a governed, production-shaped app, fast enough to build live in a design-thinking session |

---

## Short of time? Do Lab 2 and Lab 5

If you only have about **75 minutes**, do **[Lab 2](lab2_ask_the_agent.md)** and then
**[Lab 5](lab5_dashboard_with_coco.md)**. Together they tell the whole story:

| | Lab 2 - Ask the agent | Lab 5 - Build a dashboard |
| --- | --- | --- |
| Who it's for | Anyone who needs **answers** | Anyone who needs to **show** the answers to the business |
| What you see | Plain-English questions answered over SAP data **and** contract documents, with the SQL and sources behind each answer | A supply chain risk story built from SAP data products in minutes, plus the technical architecture behind it |
| Snowflake capabilities | Cortex Agents, Cortex Analyst, semantic views, verified queries, Cortex Search | Cortex Code (CoCo), Streamlit in Snowflake, cross-database queries over SAP data products, semantic views |
| Why it matters | Shows that AI answers on SAP data can be **trusted and audited** | Shows how fast an idea becomes a **high-fidelity prototype** on production-shaped data |

Both labs only need the setup, so you can skip Labs 1, 3 and 4 without missing anything you need. Come back to them
later: Lab 1 explains the data behind the answers, Lab 3 shows what makes an agent good, and Lab 4 shows where the
risk scores come from.

---

## What you'll learn in each lab

### Lab 1 - Explore the data (15 min)
*Your SAP vendor master lists 50 suppliers. Two companies that aren't in it at all each sit behind 48 of them.*
- Query the **4 SAP data products** in place, with the same quoted names SAP BDC publishes.
- See how external **trade data** (bills of lading) names suppliers that aren't in SAP at all.
- Read the **GNN outputs**: risk scores, predicted hidden links and bottlenecks, including the 2 CRITICAL suppliers,
  both in Australia.

### Lab 2 - Ask the agent, then check its work (25 min)
*Risk numbers live in tables, obligations live in contracts, and your team usually needs both.*
- Learn what a **Cortex Agent** is and how it chooses between **Cortex Analyst** (SQL over a semantic view) and
  **Cortex Search** (meaning-based search over contract text).
- Open **Show Traces** to see the plan, the tool and the **exact SQL** behind every answer, and whether it used a
  **verified query** (SQL a person approved in advance).
- Run the agent's contract search yourself, and see search by meaning find "termination" when you asked about
  "walking away".

### Lab 3 - Build your own agent (20 min)
*In Lab 2 the agent seemed to "just know" when to query data and when to read contracts. It doesn't.*
- Build an agent from the same parts in **Agent Studio**: a semantic view tool and a search service tool.
- Compare it with the tuned agent using the traces, and see what **orchestration instructions** and **tool
  descriptions** change.
- Learn that anything you click in the UI can also be written as a version-controlled `CREATE AGENT` script.

### Lab 4 - Retrain the GNN (optional, 45-60 min)
*Every number the agent gave you came from a model that learned the shape of your supply network.*
- Run the PyTorch Geometric notebook on **Snowpark Container Services**, right next to the SAP data.
- Produce your own risk scores, tagged with a **model version**, and compare them with the precomputed run.
- *Needs a non-trial account*, because the notebook installs Python packages from the internet.

### Lab 5 - Build a dashboard with one prompt (45-60 min)
*In Labs 1 to 4 you asked questions. In Lab 5 you hand the business a working app.*
- Paste one prompt into **Cortex Code (CoCo)** in Snowsight and get a 2-page **Streamlit in Snowflake** app: a
  supply chain risk story read from top to bottom, and a technical architecture page.
- See the value in business terms: **$143.3M** of SAP spend, **$18.6M** of it with high-risk suppliers, and the
  hidden Tier 2 bottlenecks behind it.
- Grow the app one prompt at a time, and learn how to use the same pattern in a **design-thinking workshop** to go
  from idea to high-fidelity demo before building for production.

---

## Suggested paths

| You have | Do | Total time |
| --- | --- | --- |
| About 75 minutes | **Lab 2 + Lab 5** | about 70-85 min |
| About 2 hours | Lab 1, Lab 2, Lab 3, Lab 5 | about 105-120 min |
| Half a day, non-trial account | All five labs | about 2.5-3 hours |

**When you're done:** run `snowsight/99_remove_setup.sql` to remove everything the course created (see
[Clean up](../README.md#clean-up)).
