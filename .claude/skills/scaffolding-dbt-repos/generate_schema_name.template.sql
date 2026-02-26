{%- macro generate_schema_name(custom_schema_name, node) -%}
    {#
        Maps layer folders to target schemas.
        In prod: uses the custom_schema_name as-is (staging, intermediate, marts).
        In dev/staging: prefixes with target name (e.g., dev_raw, staging_intermediate).

        Schema mapping per environment:
          Layer        | dev                   | staging                   | prod
          -------------|------------------------|---------------------------|-------------
          Staging      | dev_staging           | staging_staging           | staging
          Intermediate | dev_intermediate      | staging_intermediate      | intermediate
          Marts        | dev_marts             | staging_marts             | marts
    #}
    {%- set default_schema = target.schema -%}

    {%- if target.name == 'prod' -%}
        -- CUSTOMISE: change 'prod' to match your production target name (e.g. 'prd', 'production')
        {{ custom_schema_name | trim if custom_schema_name else default_schema }}

    {%- else -%}
        {%- if custom_schema_name -%}
            -- CUSTOMISE: prefix pattern is "{target_name}_{schema}".
            -- Examples: dev_staging, stg_intermediate, uat_marts.
            -- Change target names in profiles.yml to control the prefix.
            {{ target.name }}_{{ custom_schema_name | trim }}
        {%- else -%}
            {{ default_schema }}
        {%- endif -%}

    {%- endif -%}
{%- endmacro -%}
