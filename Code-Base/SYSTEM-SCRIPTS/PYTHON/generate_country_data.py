import requests
import json

def generate_country_inserts(url="https://restcountries.com/v3.1/all"):
    try:
        response = requests.get(url)
        response.raise_for_status() # Raise an exception for HTTP errors
        countries_data = response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data: {e}")
        return

    sql_statements = []
    for country in countries_data:
        name = country.get('name', {}).get('common', '').replace("'", "''")
        official_name = country.get('name', {}).get('official', '').replace("'", "''")
        iso2 = country.get('cca2', '')
        iso3 = country.get('cca3', '')
        numeric_code = country.get('ccn3', '') # Numeric code might be missing for some
        region = country.get('region', '')
        subregion = country.get('subregion', '')
        independent = country.get('independent', False)
        status = 'officially assigned' # Or you can try to derive this from data if available

        # Handle cases where region or subregion might be empty or null
        region_val = f"'{region}'" if region else 'NULL'
        subregion_val = f"'{subregion}'" if subregion else 'NULL'
        official_name_val = f"'{official_name}'" if official_name else 'NULL'
        numeric_code_val = f"'{numeric_code}'" if numeric_code else 'NULL'


        sql = f"INSERT INTO country (name, official_name, iso2, iso3, numeric_code, region, subregion, independent, status) VALUES ('{name}', {official_name_val}, '{iso2}', '{iso3}', {numeric_code_val}, {region_val}, {subregion_val}, {independent}, '{status}');"
        sql_statements.append(sql)

    # Print to a file or console
    with open('country_inserts.sql', 'w', encoding='utf-8') as f:
        for stmt in sql_statements:
            f.write(stmt + '\n')
    print("Generated country_inserts.sql with SQL insert statements.")

# Run the function
generate_country_inserts()
