-- =============================================================================
-- Stage 5.1 - Semantic view used by Cortex Analyst and the agent
-- Source: GET_DDL('semantic_view') on F9A3UBGT, copied verbatim (generated from
-- extract/raw/SEMANTIC_VIEW.sql - do not hand-edit; re-run the extract instead).
-- Contains 4 tables (the Stage 3 views), 9 facts, 26 dimensions and 2 verified queries.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

CREATE OR REPLACE SEMANTIC VIEW DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW
	tables (
		DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_HIDDEN_DEPENDENCIES comment='The table contains records of predicted hidden dependencies between nodes in a supply chain network. Each record represents a directional link between a source and target node, including their types and names, along with probabilistic and evidence-based metrics indicating the strength and likelihood of the dependency.',
		DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_MATERIAL_RISK comment='The table contains records of materials and their associated supply chain risk profiles. Each record represents a single material and includes details about its classification and grouping, alongside risk metrics such as criticality, overall risk scoring, risk categorization, and supplier-related risk indicators.',
		DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_RISK_SUMMARY comment='The table contains a summary of supply chain risk assessments aggregated by category. Each record captures the distribution of risk severity levels and an average risk score across those categories.',
		DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_SUPPLIER_RISK comment='The table contains records of supplier risk assessments derived from supply chain analysis. Each record represents a single vendor and includes geographic, categorical, and scored risk attributes, along with order volume and value metrics.'
	)
	facts (
		VW_HIDDEN_DEPENDENCIES.PROBABILITY as PROBABILITY comment='The probability score representing the likelihood of a hidden dependency existing within the supply chain risk network.',
		VW_MATERIAL_RISK.AVG_SUPPLIER_RISK as AVG_SUPPLIER_RISK comment='The average risk score associated with suppliers for a given material.',
		VW_MATERIAL_RISK.CRITICALITY_SCORE as CRITICALITY_SCORE comment='A numerical score indicating the criticality level of a material within the supply chain risk assessment.',
		VW_MATERIAL_RISK.GNN_RISK_SCORE as GNN_RISK_SCORE comment='A numerical score representing the Graph Neural Network (GNN)-calculated risk level associated with a material in the supply chain.',
		VW_RISK_SUMMARY.AVG_RISK_SCORE as AVG_RISK_SCORE comment='The average risk score associated with supply chain risk assessment.',
		VW_SUPPLIER_RISK.CONFIDENCE as CONFIDENCE comment='A confidence score indicating the level of certainty associated with the supplier risk assessment.',
		VW_SUPPLIER_RISK.GNN_RISK_SCORE as GNN_RISK_SCORE comment='The Graph Neural Network (GNN)-derived risk score assigned to a supplier, represented as a floating-point value.',
		VW_SUPPLIER_RISK.REGION_RISK as REGION_RISK comment='A numerical risk score representing the level of risk associated with a supplier''s geographic region.',
		VW_SUPPLIER_RISK.TOTAL_ORDER_VALUE as TOTAL_ORDER_VALUE comment='The total monetary value of all orders associated with a supplier.'
	)
	dimensions (
		VW_HIDDEN_DEPENDENCIES.EVIDENCE_STRENGTH as EVIDENCE_STRENGTH comment='The strength of evidence supporting an identified hidden dependency or supply chain risk relationship.',
		VW_HIDDEN_DEPENDENCIES.LINK_ID as LINK_ID comment='Unique identifier for a link representing a dependency relationship within the supply chain network.',
		VW_HIDDEN_DEPENDENCIES.SOURCE_NAME as SOURCE_NAME comment='The name of the source entity within the supply chain dependency relationship.',
		VW_HIDDEN_DEPENDENCIES.SOURCE_NODE_ID as SOURCE_NODE_ID comment='The unique identifier of the source node in the supply chain dependency graph.',
		VW_HIDDEN_DEPENDENCIES.SOURCE_NODE_TYPE as SOURCE_NODE_TYPE comment='The type of the source node in the supply chain dependency graph.',
		VW_HIDDEN_DEPENDENCIES.TARGET_NAME as TARGET_NAME comment='The name of the target entity within the supply chain dependency relationship.',
		VW_HIDDEN_DEPENDENCIES.TARGET_NODE_ID as TARGET_NODE_ID comment='The unique identifier of the target node within the supply chain dependency graph.',
		VW_HIDDEN_DEPENDENCIES.TARGET_NODE_TYPE as TARGET_NODE_TYPE comment='The type classification of the target node within the supply chain dependency graph.',
		VW_HIDDEN_DEPENDENCIES.PREDICTED_AT as PREDICTED_AT comment='The timestamp indicating when the hidden dependency prediction was generated.',
		VW_MATERIAL_RISK.DESCRIPTION as DESCRIPTION comment='A brief textual description of the material and its associated supply chain risk characteristics.',
		VW_MATERIAL_RISK.MATERIAL_GROUP as MATERIAL_GROUP comment='The material group classification used to categorize materials within the supply chain.',
		VW_MATERIAL_RISK.MATERIAL_ID as MATERIAL_ID comment='Unique identifier for a material within the supply chain.',
		VW_MATERIAL_RISK.NUM_SUPPLIERS as NUM_SUPPLIERS comment='The number of suppliers associated with a given material.',
		VW_MATERIAL_RISK.RISK_CATEGORY as RISK_CATEGORY comment='The category of risk associated with a material in the supply chain.',
		VW_RISK_SUMMARY.CATEGORY as CATEGORY comment='The risk category classification assigned to a supply chain entity or event.',
		VW_RISK_SUMMARY.CRITICAL_COUNT as CRITICAL_COUNT comment='The total count of critical risk items identified within the supply chain risk summary.',
		VW_RISK_SUMMARY.HIGH_COUNT as HIGH_COUNT comment='The count of high-risk items or events identified within the supply chain risk summary.',
		VW_RISK_SUMMARY.LOW_COUNT as LOW_COUNT comment='The count of supply chain risk items classified as low risk.',
		VW_RISK_SUMMARY.MEDIUM_COUNT as MEDIUM_COUNT comment='The count of medium-risk items identified in the supply chain risk summary.',
		VW_RISK_SUMMARY.TOTAL_COUNT as TOTAL_COUNT comment='The total count of records or items associated with the supply chain risk summary entry.',
		VW_SUPPLIER_RISK.COUNTRY_CODE as COUNTRY_CODE comment='Two-letter ISO country code identifying the country associated with the supplier.',
		VW_SUPPLIER_RISK.RISK_CATEGORY as RISK_CATEGORY comment='The category of risk associated with a supplier.',
		VW_SUPPLIER_RISK.TIER as TIER comment='The tier level of the supplier within the supply chain hierarchy.',
		VW_SUPPLIER_RISK.TOTAL_ORDERS as TOTAL_ORDERS comment='The total number of orders placed with a supplier.',
		VW_SUPPLIER_RISK.VENDOR_ID as VENDOR_ID comment='Unique identifier assigned to a vendor or supplier.',
		VW_SUPPLIER_RISK.VENDOR_NAME as VENDOR_NAME comment='The name of the vendor or supplier.'
	)
	ai_verified_queries (
		"Which Materials have the highest GNN risk Score?" AS ( 
QUESTION 'Which Materials have the highest GNN risk Score?' 
VERIFIED_AT 1785167680
VERIFIED_BY 'I829967'
ONBOARDING_QUESTION false
SQL 'SELECT
  material_id,
  description,
  material_group,
  risk_category,
  gnn_risk_score
FROM
  vw_material_risk
ORDER BY
  gnn_risk_score DESC NULLS LAST
  /* Generated by Cortex Analyst (request_id: 99111058-2ad3-4544-89c4-51c2026064d1) */'),
		"Which Tier 1 suppliers have a GNN risk score above 0.6?" AS ( 
QUESTION 'Which Tier 1 suppliers have a GNN risk score above 0.6?' 
VERIFIED_AT 1785167703
VERIFIED_BY 'I829967'
ONBOARDING_QUESTION false
SQL 'SELECT
  vendor_id,
  vendor_name,
  country_code,
  risk_category,
  tier,
  gnn_risk_score,
  confidence,
  total_orders,
  total_order_value
FROM
  vw_supplier_risk
WHERE
  tier = 1
  AND gnn_risk_score > 0.6
ORDER BY
  gnn_risk_score DESC NULLS LAST
  /* Generated by Cortex Analyst (request_id: 178ff3df-13ac-4698-8371-e64740376d17) */')
	)
	with extension (CA='{"tables":[{"name":"VW_HIDDEN_DEPENDENCIES","dimensions":[{"name":"EVIDENCE_STRENGTH"},{"name":"LINK_ID"},{"name":"SOURCE_NAME"},{"name":"SOURCE_NODE_ID"},{"name":"SOURCE_NODE_TYPE"},{"name":"TARGET_NAME"},{"name":"TARGET_NODE_ID"},{"name":"TARGET_NODE_TYPE"}],"facts":[{"name":"PROBABILITY"}],"time_dimensions":[{"name":"PREDICTED_AT"}]},{"name":"VW_MATERIAL_RISK","dimensions":[{"name":"DESCRIPTION"},{"name":"MATERIAL_GROUP"},{"name":"MATERIAL_ID"},{"name":"NUM_SUPPLIERS"},{"name":"RISK_CATEGORY"}],"facts":[{"name":"AVG_SUPPLIER_RISK"},{"name":"CRITICALITY_SCORE"},{"name":"GNN_RISK_SCORE"}]},{"name":"VW_RISK_SUMMARY","dimensions":[{"name":"CATEGORY"},{"name":"CRITICAL_COUNT"},{"name":"HIGH_COUNT"},{"name":"LOW_COUNT"},{"name":"MEDIUM_COUNT"},{"name":"TOTAL_COUNT"}],"facts":[{"name":"AVG_RISK_SCORE"}]},{"name":"VW_SUPPLIER_RISK","dimensions":[{"name":"COUNTRY_CODE"},{"name":"RISK_CATEGORY"},{"name":"TIER"},{"name":"TOTAL_ORDERS"},{"name":"VENDOR_ID"},{"name":"VENDOR_NAME"}],"facts":[{"name":"CONFIDENCE"},{"name":"GNN_RISK_SCORE"},{"name":"REGION_RISK"},{"name":"TOTAL_ORDER_VALUE"}]}]}');
