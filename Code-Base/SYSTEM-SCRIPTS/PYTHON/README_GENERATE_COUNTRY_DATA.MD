README_generate_country_data.md
Automating Country Data Population for PostgreSQL
This guide outlines the process of programmatically fetching worldwide country data using a Python script, transforming it into SQL INSERT statements, and then populating a PostgreSQL database running in Docker.

Table of Contents
- [1. Purpose](#1-purpose)
- [2. Prerequisites](#2-prerequisites)
- [3. Project Structure Setup](#3-project-structure-setup)
- [4. Python Virtual Environment Setup](#4-python-virtual-environment-setup)
- [5. Create the Python Script](#5-create-the-python-script)
- [6. Generate the SQL `INSERT` File](#6-generate-the-sql-insert-file)
- [7. PostgreSQL Docker Setup](#7-postgresql-docker-setup)
- [8. Populate the Database](#8-populate-the-database)
- [9. Verify Data (Optional)](#9-verify-data-optional)

# 1. Purpose
This process automates the population of your country table in PostgreSQL with comprehensive and up-to-date information about countries around the world. It leverages a public API (Rest Countries) to fetch data and generates SQL INSERT statements, ensuring accurate ISO codes, names, 
regions, and other relevant details.

# 2. Prerequisites
Before you begin, ensure you have the following installed on your system:

Docker & Docker Compose: For running your PostgreSQL database.
Python 3: The scripting language for fetching and processing data.
psql client: The PostgreSQL command-line client, typically installed with PostgreSQL or as a separate package.
You should also have your country table already defined in your PostgreSQL database:

```SQL

CREATE TABLE country (
    id SERIAL PRIMARY KEY,                           -- Internal system ID
    name VARCHAR(128) NOT NULL,                      -- Country name (e.g., "United Kingdom")
    official_name VARCHAR(256),                      -- Official name (e.g., "United Kingdom of Great Britain and Northern Ireland")
    iso2 CHAR(2) NOT NULL UNIQUE,                    -- ISO 3166-1 alpha-2 (e.g., "GB")
    iso3 CHAR(3) NOT NULL UNIQUE,                    -- ISO 3166-1 alpha-3 (e.g., "GBR")
    numeric_code CHAR(3),                            -- ISO 3166-1 numeric code (e.g., "826")
    region VARCHAR(64),                              -- UN region (e.g., "Europe")
    subregion VARCHAR(64),                           -- UN subregion (e.g., "Northern Europe")
    independent BOOLEAN DEFAULT TRUE,                -- Whether the country is independent (e.g., not a territory)
    status VARCHAR(64),                              -- Status (e.g., "officially assigned")
    enabled BOOLEAN DEFAULT TRUE,                    -- Can be used in the system
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Timestamps for tracking
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

# 3. Project Structure Setup
Let's set up a clean directory structure for your project. Assuming your main project root is `Code-Base`, create subdirectories for scripts:

```Bash

# Navigate to your main project directory
cd ~/Documents/Projects/Calu/Code-Base

# Create the script directories
mkdir -p SYSTEM-SCRIPTS/PYTHON
```

After this, your project structure will look something like this:
```
Calu/
└── Code-Base/
    ├── SYSTEM-SCRIPTS/
    │       └── PYTHON/
    │           └── # (Your Python script will go here)
    └── # (Other project files, e.g., docker-compose.yml)
```

# 4. Python Virtual Environment Setup
It's crucial to use a Python virtual environment to manage dependencies for your project. This keeps project-specific libraries isolated from your global Python installation.

1 - Navigate to the project root:

```Bash

cd ~/Documents/Projects/Calu/Code-Base
```

2 - Create the virtual environment:

```Bash

python3 -m venv .venv
```

This creates a `.venv` directory in your `Code-Base` folder.

3 - Activate the virtual environment:

- On macOS/Linux:
```Bash

source .venv/bin/activate
```

- On Windows (Command Prompt):
```DOS

.venv\Scripts\activate.bat
```

- On Windows (PowerShell):
```PowerShell

.venv\Scripts\Activate.ps1
```

Your terminal prompt should now show `(.venv)` at the beginning, indicating the environment is active.

4 - Install necessary Python packages:
While the virtual environment is active, install the `requests` library, which your Python script will use to make API calls.

```Bash

pip install requests
```

# 5. Create the Python Script
If the file doesn't exist already, create a new file named `generate_country_data.py` inside `SYSTEM-SCRIPTS/PYTHON/`.

File Path: `~/Documents/Projects/Calu/Code-Base/SYSTEM-SCRIPTS/PYTHON/generate_country_data.py`

Script Content (`generate_country_data.py`):

```Python

import requests
import json
import os

def generate_country_inserts(output_filename="country_inserts.sql"):
    """
    Fetches country data from the Rest Countries API and generates SQL INSERT statements.
    """
    api_url = "https://restcountries.com/v3.1/all"
    print(f"Fetching data from: {api_url}")

    try:
        response = requests.get(api_url)
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
        countries_data = response.json()
        print(f"Successfully fetched {len(countries_data)} countries.")
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from API: {e}")
        return

    sql_statements = []
    # Add a header for the SQL file
    sql_statements.append("-- SQL INSERT statements for the 'country' table")
    sql_statements.append("-- Generated by generate_country_data.py")
    sql_statements.append("-- Make sure the 'country' table exists before running this script.")
    sql_statements.append("\nBEGIN;") # Start a transaction for atomicity

    for country in countries_data:
        # Extract data, handling potential missing fields and quoting for SQL
        name = country.get('name', {}).get('common', '').replace("'", "''")
        official_name = country.get('name', {}).get('official', '')
        if official_name:
            official_name = f"'{official_name.replace(\"'\", \"''\")}'"
        else:
            official_name = 'NULL'

        iso2 = country.get('cca2', '')
        iso3 = country.get('cca3', '')
        numeric_code = country.get('ccn3', '')
        if numeric_code:
            numeric_code = f"'{numeric_code}'"
        else:
            numeric_code = 'NULL'

        region = country.get('region', '')
        if region:
            region = f"'{region.replace(\"'\", \"''\")}'"
        else:
            region = 'NULL'

        subregion = country.get('subregion', '')
        if subregion:
            subregion = f"'{subregion.replace(\"'\", \"''\")}'"
        else:
            subregion = 'NULL'

        # 'independent' is a boolean, directly use Python's True/False
        independent = 'TRUE' if country.get('independent', False) else 'FALSE'

        # Default status for most officially assigned countries
        status = 'officially assigned'

        # Construct the INSERT statement
        sql = (
            f"INSERT INTO country (name, official_name, iso2, iso3, numeric_code, region, subregion, independent, status)\n"
            f"VALUES ('{name}', {official_name}, '{iso2}', '{iso3}', {numeric_code}, {region}, {subregion}, {independent}, '{status}');"
        )
        sql_statements.append(sql)

    sql_statements.append("\nCOMMIT;") # End the transaction

    # Determine the output path (relative to the script's location, or adjust as needed)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, output_filename)

    # Write the SQL statements to the file
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            for stmt in sql_statements:
                f.write(stmt + '\n')
        print(f"SQL INSERT statements successfully written to: {output_path}")
    except IOError as e:
        print(f"Error writing SQL file: {e}")

if __name__ == "__main__":
    generate_country_inserts()
```
# 6. Generate the SQL `INSERT` File
Make sure your virtual environment is active (you should see (.venv) in your terminal prompt) before running the script.

1. Navigate to your project root (if you aren't already there):

```Bash

cd ~/Documents/Projects/Calu/Code-Base
```

2. Run the Python script:

```Bash

python ./SYSTEM-SCRIPTS/PYTHON/generate_country_data.py
```

    This script will:

    . Fetch country data from the API.
    . Process the data and generate SQL `INSERT` statements.
    . Save these statements into a file named `country_inserts.sql` in the same directory as the Python script (SYSTEM-SCRIPTS/PYTHON/).

# 7. PostgreSQL Docker Setup
Ensure your docker-compose.yml file defines your PostgreSQL service. The relevant part for your setup should look like this:

File Path: ~/Documents/Projects/Calu/Code-Base/docker-compose.yml (or wherever your docker-compose.yml is located)

```YAML

# ... (other services or docker-compose configuration)
services:
  postgres:
    image: postgres:15
    container_name: postgres
    restart: always
    environment:
      POSTGRES_USER: postgres  # 🔧 Change this if you want a custom DB user
      POSTGRES_PASSWORD: postgres  # 🔧 Change this for security in production
      POSTGRES_DB: calu_system  # 🔧 Change to your desired DB name
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432" # Host_port:Container_port
# ... (other services or docker-compose configuration)

volumes:
  pgdata:
```

Understanding the `psql` command parameters from `docker-compose.yml`:

. `-h localhost` (Host): This refers to your local machine. Since you mapped the container's port to your host's port (`5432:5432`), your local machine can connect to the Dockerized PostgreSQL server via `localhost`.
. `-p 5432` (Port): This `5432` comes from the left side of the `ports: - "5432:5432"` mapping. It's the port on your host machine that is exposed by the Docker container.
. `-U postgres` (User): This value is taken directly from the `POSTGRES_USER: postgres` environment variable defined for your `postgres` service.
. `-d calu_system` (Database Name): This value is taken directly from the `POSTGRES_DB: calu_system` environment variable defined for your `postgres` service.
# 8. Populate the Database
Now that you have the `country_inserts.sql` file and your PostgreSQL container defined, you can populate the database.

1. Ensure your PostgreSQL container is running:
From your project root (`~/Documents/Projects/Calu/Code-Base`), where your `docker-compose.ym`l is located:

```Bash

docker-compose up -d postgres
```

(This will start only the `postgres` service in detached mode. If you have other services you want to start, you might use `docker-compose up -d`).

2. Run the `psql` command to load data:
Execute this command from your local machine's terminal (the same terminal where you ran `docker-compose` commands). Make sure you specify the correct path to your generated `.sql` file.

```Bash

PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d calu_system -f ./country_inserts.sql
```

You will likely be prompted for the postgres user's password, which is postgres as per your docker-compose.yml.

# 9. Verify Data (Optional)
To confirm that the data has been successfully inserted, you can connect to your database using `psql` and query the `country` table:

```Bash

PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d calu_system
```

(Enter password `postgres` when prompted)

Once connected to the `calu_system` database, run a simple query:

```SQL

SELECT count(*) FROM country;
SELECT name, iso2, region FROM country LIMIT 10;
\q -- (to exit psql)
```

You should see a count reflecting the number of countries inserted (around 250, depending on the API data at the time) and a sample of the data.
