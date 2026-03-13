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
      - John Doe's staging schema   → JDOE_STAGING
      - Jane Smith's marts schema   → JSMITH_MARTS
      - Bob Johnson's intermediate  → BJOHNSON_INTERMEDIATE
  
  How It Works:
    1. Extracts the Snowflake username from the connection (target.user)
    2. Parses first name and last name from the username
    3. Creates prefix: first_initial + last_name
    4. Combines prefix with custom schema name (from dbt_project.yml)
    5. Returns the final schema name (e.g., JDOE_STAGING)
  
  Configuration Requirements:
    In profiles.yml, set the 'user' field using one of these formats:
      - Okta/SSO email: john.doe@company.com
      - Snowflake username: JOHN.DOE or JDOE
      - Full name format: john.doe
    
    The macro automatically handles all three formats.
  
  Database Configuration:
    In profiles.yml, set:
      database: SANDBOX_DBT_TRAINING  # Shared database for all users
    
    All users share the same database but get unique schemas.
  
  Example Flow:
    Given profiles.yml:
      user: john.doe@company.com
      database: SANDBOX_DBT_TRAINING
      
    And dbt_project.yml:
      models:
        dbt_learning:
          staging:
            +schema: staging
    
    Result:
      Database: SANDBOX_DBT_TRAINING
      Schema: JDOE_STAGING
      Full path: SANDBOX_DBT_TRAINING.JDOE_STAGING.STG_CUSTOMERS
#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    
    {#- 
      STEP 1: Extract username from Snowflake connection
      --------------------------------------------------
      target.user comes from profiles.yml and could be:
        - Email: john.doe@company.com
        - Snowflake user: JOHN.DOE
        - Simple format: john.doe
    -#}
    {%- set username = target.user | lower -%}
    
    {#-
      STEP 2: Remove email domain if present
      ---------------------------------------
      If username is an email (john.doe@company.com), extract just the
      name part (john.doe) by splitting on '@' and taking the first part.
      
      split('@')[0] means:
        - Split the string by '@' delimiter
        - Take the first element (index 0)
        - "john.doe@company.com" → ["john.doe", "company.com"] → "john.doe"
    -#}
    {%- if '@' in username -%}
        {%- set username = username.split('@')[0] -%}
    {%- endif -%}
    
    {#-
      STEP 3: Parse first name and last name
      ---------------------------------------
      Usernames typically use '.' or '_' as separators:
        - john.doe → ["john", "doe"]
        - jane_smith → ["jane", "smith"]
      
      We split on both '.' and '_' to handle both formats.
    -#}
    {%- if '.' in username -%}
        {%- set name_parts = username.split('.') -%}
    {%- elif '_' in username -%}
        {%- set name_parts = username.split('_') -%}
    {%- else -%}
        {#- If no separator, treat entire username as last name -#}
        {%- set name_parts = ['', username] -%}
    {%- endif -%}
    
    {#-
      STEP 4: Extract first initial and last name
      --------------------------------------------
      - first_name[0] gets the first character of first name
      - last_name is the full last name
      
      Examples:
        - ["john", "doe"] → first_initial = "j", last_name = "doe"
        - ["jane", "smith"] → first_initial = "j", last_name = "smith"
    -#}
    {%- set first_name = name_parts[0] -%}
    {%- set last_name = name_parts[-1] -%}  {#- [-1] gets the last element -#}
    {%- set first_initial = first_name[0] if first_name else '' -%}
    
    {#-
      STEP 5: Create user prefix
      ---------------------------
      Combine first initial + last name to create the user-specific prefix.
      
      Examples:
        - j + doe → jdoe
        - j + smith → jsmith
        - b + johnson → bjohnson
      
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
           Result: JDOE_PUBLIC
      
      B) Custom schema specified in dbt_project.yml:
         - Use the custom schema name (e.g., 'staging', 'marts')
         - Combine: user_prefix + '_' + custom_schema_name
         - Example: JDOE + '_' + STAGING → JDOE_STAGING
      
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
  
  Issue: Multiple underscores (e.g., "J_DOE_STAGING")
  Cause: Username has multiple parts (e.g., "john_middle_doe")
  Fix: Use simple format (john.doe) or just first.last
  
  Issue: Schema name too long (Snowflake limit: 255 characters)
  Cause: Very long last name + long schema name
  Fix: Truncate last name in the macro or use a shorter alias
  
  
  VERIFICATION QUERIES
  ====================
  
  After running dbt run, verify schemas were created correctly:
  
    -- Show all schemas with your prefix
    SHOW SCHEMAS LIKE 'JDOE_%' IN DATABASE SANDBOX_DBT_TRAINING;
    
    -- Verify a specific model's location
    SELECT 
      table_catalog as database,
      table_schema as schema,
      table_name
    FROM information_schema.tables
    WHERE table_schema LIKE 'JDOE_%'
      AND table_name = 'STG_CUSTOMERS';
#}
