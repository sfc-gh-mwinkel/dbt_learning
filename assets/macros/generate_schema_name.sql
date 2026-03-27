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
      - Jon Snow's staging schema      → JSNOW_STAGING
      - Sara Glacier's marts schema    → SGLACIER_MARTS
      - Bob Johnson's intermediate     → BJOHNSON_INTERMEDIATE
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
    
    {#- 
      STEP 1: Extract username from Snowflake connection
      --------------------------------------------------
      target.user comes from profiles.yml and could be:
        - Email: jon.snow@company.com
        - Snowflake user: JON.SNOW
        - Simple format: jon.snow
        - No separator: JSNOW (used as-is)
    -#}
    {%- set username = target.user | lower -%}
    
    {#-
      STEP 2: Remove email domain if present
      ---------------------------------------
      If username is an email (jon.snow@company.com), extract just the
      name part (jon.snow) by splitting on '@' and taking the first part.
      
      split('@')[0] means:
        - Split the string by '@' delimiter
        - Take the first element (index 0)
        - "jon.snow@company.com" → ["jon.snow", "company.com"] → "jon.snow"
    -#}
    {%- if '@' in username -%}
        {%- set username = username.split('@')[0] -%}
    {%- endif -%}
    
    {#-
      STEP 3: Parse first name and last name
      ---------------------------------------
      Usernames typically use '.' or '_' as separators:
        - jon.snow → ["jon", "snow"]
        - sara_glacier → ["sara", "glacier"]
      
      We split on both '.' and '_' to handle both formats.
      If no separator is found, the entire username becomes the prefix
      (e.g., "jsnow" → prefix "JSNOW").
    -#}
    {%- if '.' in username -%}
        {%- set name_parts = username.split('.') -%}
    {%- elif '_' in username -%}
        {%- set name_parts = username.split('_') -%}
    {%- else -%}
        {#- If no separator (e.g., JSNOW), use entire username as prefix -#}
        {%- set name_parts = ['', username] -%}
    {%- endif -%}
    
    {#-
      STEP 4: Extract first initial and last name
      --------------------------------------------
      - first_name[0] gets the first character of first name
      - last_name is the full last name
      
      Examples:
        - ["jon", "snow"] → first_initial = "j", last_name = "snow"
        - ["sara", "glacier"] → first_initial = "s", last_name = "glacier"
        - ["", "jsnow"] → first_initial = "", last_name = "jsnow" (no separator)
    -#}
    {%- set first_name = name_parts[0] -%}
    {%- set last_name = name_parts[-1] -%}  {#- [-1] gets the last element -#}
    {%- set first_initial = first_name[0] if first_name else '' -%}
    
    {#-
      STEP 5: Create user prefix
      ---------------------------
      Combine first initial + last name to create the user-specific prefix.
      
      Examples:
        - j + snow → jsnow
        - s + glacier → sglacier
        - "" + jsnow → jsnow (no separator, used as-is)
      
      upper() converts to uppercase for Snowflake convention.
    -#}
    {%- set user_prefix = (first_initial ~ last_name) | upper -%}
    
    {#-
      STEP 6: Combine prefix with schema name
      ----------------------------------------
      Two scenarios:
      
      A) No custom schema specified (custom_schema_name is none):
         - Use target.schema from profiles.yml
         - Example: If target.schema = 'public'
           Result: JSNOW_PUBLIC
      
      B) Custom schema specified in dbt_project.yml:
         - Use the custom schema name (e.g., 'staging', 'marts')
         - Combine: user_prefix + '_' + custom_schema_name
         - Example: JSNOW + '_' + STAGING → JSNOW_STAGING
      
      The trim() filter removes any accidental whitespace from YAML configs.
    -#}
    {%- if custom_schema_name is none -%}
        {#- No custom schema - use default from profiles.yml with user prefix -#}
        {{ user_prefix }}_{{ target.schema | upper }}
    {%- else -%}
        {#- Custom schema from dbt_project.yml - combine with user prefix -#}
        {{ user_prefix }}_{{ custom_schema_name | trim | upper }}
    {%- endif -%}

{%- endmacro %}

{#
  TESTING THE MACRO
  =================
  
  To test this macro with different usernames, you can use dbt's compile command:
  
    dbt compile --select stg_customers
  
  Then check the compiled SQL in:
    target/compiled/dbt_learning/models/staging/stg_customers.sql
  
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
