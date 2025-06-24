# Automating Currency Data Population for PostgreSQL

This guide outlines the process of programmatically populating your `currency` table using a Python script. It fetches ISO 4217 currency data from trusted online sources, including symbols, and transforms it into `SQL INSERT` statements. The final result is saved as a `.sql` file ready to load into your PostgreSQL database.

---

## 📌 Table of Contents

- [Automating Currency Data Population for PostgreSQL](#automating-currency-data-population-for-postgresql)
  - [📌 Table of Contents](#-table-of-contents)
  - [🎯 Purpose](#-purpose)
  - [🧱 Currency Table Structure](#-currency-table-structure)
  - [🧠 Python Script Overview](#-python-script-overview)
  - [🛠 Setup Instructions](#-setup-instructions)
  - [🚀 Run the Script](#-run-the-script)
  - [🐘 Load Into PostgreSQL](#-load-into-postgresql)
  - [✅ Verify Results](#-verify-results)
  - [📎 Notes on Data Sources](#-notes-on-data-sources)

---

## 🎯 Purpose

To automate and standardize the population of the `currency` table so all developers and environments start from the same baseline. It eliminates manual setup and prevents discrepancies in default currencies or values.

---

## 🧱 Currency Table Structure

This is the `currency` table used:

```sql
CREATE TABLE currency (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(3) UNIQUE NOT NULL,     -- ISO 4217 code, e.g. 'USD', 'EUR'
    name            VARCHAR(50) NOT NULL,           -- Full name (e.g. 'British Pound Sterling')
    symbol          VARCHAR(10),                    -- Common currency symbol, e.g. '£'
    minor_unit      INTEGER NOT NULL DEFAULT 2,     -- Decimal precision (0 = no decimals)
    iso_numeric     VARCHAR(3),                     -- ISO numeric code (e.g. '840' for USD)
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
```

---

## 🧠 Python Script Overview

- Downloads ISO 4217 data from [DataHub](https://datahub.io/core/currency-codes/)
- Adds symbol info from a GitHub-maintained format file
- Filters out duplicates and invalid entries
- Outputs a `currency_inserts.sql` file wrapped in a `BEGIN/COMMIT` transaction

---

## 🛠 Setup Instructions

From your project root:

```bash
cd ~/Documents/Projects/Calu/Code-Base
python3 -m venv .venv
source .venv/bin/activate
pip install requests
```

Make sure your script is in:

```
Code-Base/SYSTEM-SCRIPTS/PYTHON/generate_currency_data.py
```

---

## 🚀 Run the Script

```bash
cd SYSTEM-SCRIPTS/PYTHON
python generate_currency_data.py
```

It will create:

```
currency_inserts.sql
```

In the same folder.

---

## 🐘 Load Into PostgreSQL

```bash
psql -h localhost -p 5432 -U postgres -d calu_system -f ./SYSTEM-SCRIPTS/PYTHON/currency_inserts.sql
```

You’ll be prompted for the password (usually `postgres` during local dev).

---

## ✅ Verify Results

```sql
SELECT COUNT(*) FROM currency;
SELECT code, name, symbol, minor_unit FROM currency ORDER BY code LIMIT 10;
```

---

## 📎 Notes on Data Sources

This script uses **two distinct data sources**:

1. **Currency Code Source** (CSV): from [DataHub.io](https://datahub.io/core/currency-codes/)  
   - Provides `code`, `name`, `numeric_code`, `minor_unit`, etc.
   - Contains duplicates (e.g. multiple entries for `USD` across different countries).
   - ✅ The script filters these using a `seen_codes` set.

2. **Symbol Source** (JSON): from [Xsolla GitHub currency-format](https://github.com/xsolla/currency-format)  
   - Provides symbol and formatting info.
   - Queried **per unique currency code**, not iterated.

---

_Last generated: 2025-06-19 16:00:59 UTC_
