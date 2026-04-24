{# 
  MULTI-USER SCHEMA NAMING MACRO
  ===============================
  
  Purpose:
    This macro generates user-specific schema names for multi-user dbt environments.
    Each user gets their own isolated schemas to prevent conflicts when multiple
    users work in the same Snowflake database.
  
  Naming Pattern:
    <first_initial><last_name>_<schema_name>
    
    Examples:
      - Jon Snows staging schema      → JSNOW_STAGING
      - Sara Glaciers marts schema    → SGLACIER_MARTS
      - Bob Johnsons intermediate     → BJOHNSON_INTERMEDIATE
      - No-separator username (TSNOW)  → TSNOW_STAGING
  
  How It Works:
    1. Extracts the Snowflake username from the connection (target.user)
    2. Parses first name and last name from the username
    3. Creates prefix: first_initial + last_name
    4. Combines prefix with custom schema name (from dbt_project.yml)
    5. Returns the final schema name (e.g., JSNOW_STAGING)
  
  Configuration Requirements:
    In profiles.yml, set the 'user' field using one of these formats:
      - Okta/SSO email: jon.snow@company.com
      - Snowflake username: JON.SNOW or JSNOW
      - Full name format: jon.snow
    
    The macro automatically handles all three formats.
  
  Database Configuration:
    In profiles.yml, set:
      database: SANDBOX_DBT_TRAINING  # Shared database for all users
    
    All users share the same database but get unique schemas.
  
  Example Flow:
    Given profiles.yml:
      user: jon.snow@company.com
      database: SANDBOX_DBT_TRAINING
      
    And dbt_project.yml:
      models:
        dbt_learning:
          staging:
            +schema: staging
    
    Result:
      Database: SANDBOX_DBT_TRAINING
      Schema: JSNOW_STAGING
      Full path: SANDBOX_DBT_TRAINING.JSNOW_STAGING.STG_CUSTOMERS
#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set user_prefix = get_user_prefix() | trim -%}
    {%- if custom_schema_name is none -%}
        {{ user_prefix }}_{{ target.schema | upper }}
    {%- else -%}
        {{ user_prefix }}_{{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}

{#
  TESTING THE MACRO
  =================
  
  To test this macro with different usernames, you can use dbts compile command:
  
    dbt compile --select stg_raw__customers
  
  Then check the compiled SQL in:
    target/compiled/dbt_learning/models/staging/stg_raw__customers.sql
  
  The FROM clause will show the actual schema name generated.
  
  
  TROUBLESHOOTING
  ===============
  
  Issue: Schema name looks wrong (e.g., "_STAGING" with no user prefix)
  Cause: Username parsing failed
  Fix: Check your profiles.yml user field format
  
  Issue: Multiple underscores (e.g., "J_SNOW_STAGING")
  Cause: Username has multiple parts (e.g., "jon_middle_snow")
  Fix: Use simple format (jon.snow) or just first.last
  
  Issue: Schema name too long (Snowflake limit: 255 characters)
  Cause: Very long last name + long schema name
  Fix: Truncate last name in the macro or use a shorter alias
  
  
  VERIFICATION QUERIES
  ====================
  
  After running dbt run, verify schemas were created correctly:
  
    -- Show all schemas with your prefix
    SHOW SCHEMAS LIKE 'JSNOW_%' IN DATABASE SANDBOX_DBT_TRAINING;
    
    -- Verify a specific model's location
    SELECT 
      table_catalog as database,
      table_schema as schema,
      table_name
    FROM information_schema.tables
    WHERE table_schema LIKE 'JSNOW_%'
      AND table_name = 'STG_CUSTOMERS';
#}
