import requests
import csv
import json
import os
from datetime import datetime, timezone

def generate_currency_with_symbols(output_filename="currency_inserts.sql"):
    # 📥 Step 1: Download ISO 4217 CSV
    csv_url = "https://datahub.io/core/currency-codes/r/codes-all.csv"
    resp_csv = requests.get(csv_url)
    resp_csv.raise_for_status()
    csv_rows = csv.DictReader(resp_csv.text.splitlines())
    # print("CSV headers:", csv_rows.fieldnames)

    # 📥 Step 2: Download symbol JSON from xsolla repo
    json_url = "https://raw.githubusercontent.com/xsolla/currency-format/master/currency-format.json"
    resp_json = requests.get(json_url)
    resp_json.raise_for_status()
    symbol_data = resp_json.json()

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    statements = []

    seen_codes = set()

    for row in csv_rows:
        code = (row.get("AlphabeticCode") or "").strip()

        if not code or code in seen_codes:
            continue

        seen_codes.add(code)

        name = (row.get("Currency") or "").replace("'", "''").strip()
        minor_unit_raw = row.get("MinorUnit")
        minor_unit = minor_unit_raw.strip() if minor_unit_raw else ""

        iso_numeric_raw = row.get("NumericCode")
        iso_numeric = iso_numeric_raw.strip() if iso_numeric_raw else ""

        if not code or not name or code == "No universal currency":
            continue


        # Get symbol if available
        sym_entry = symbol_data.get(code, {})
        symbol = sym_entry.get("symbol", {}).get("grapheme") or sym_entry.get("symbols", [None])[0]
        
        if symbol:
            symbol_escaped = symbol.replace("'", "''")
            symbol_sql = f"'{symbol_escaped}'"
        else:
            symbol_sql = "NULL"

        try:
            minor_unit_val = int(minor_unit)
        except (ValueError, TypeError):
            minor_unit_val = 2  # default fallback

        statements.append(
            f"INSERT INTO currency (code, name, symbol, minor_unit, iso_numeric, is_active, created_at, updated_at) "
            f"VALUES ('{code}', '{name}', {symbol_sql}, {minor_unit_val}, '{iso_numeric}', TRUE, '{now}', '{now}');"
        )

    sql = "\n".join(statements)

    out_path = os.path.join(os.getcwd(), output_filename)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(sql)

    print(f"Generated SQL: {out_path}")

if __name__ == "__main__":
    generate_currency_with_symbols()