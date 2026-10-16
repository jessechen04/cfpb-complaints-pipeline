def push_sheets(bq):
    if not SHEET_IDS:
        print("SHEET_IDS not set; skipping Sheets push")
        return

    creds, _ = google.auth.default(scopes=[
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive",
    ])
    gc = gspread.authorize(creds)

    for table in DERIVED_TABLES:
        sheet_id = SHEET_IDS.get(table)
        if not sheet_id:
            print(f"No sheet id for {table}; skipping")
            continue

        df = bq.query(f"SELECT * FROM `{PROJECT}.{DATASET}.{table}`").to_dataframe()
        df = df.astype(object).where(df.notna(), "")  # NaN/NaT -> empty cell
        rows = [df.columns.tolist()] + df.astype(str).values.tolist()

        ws = gc.open_by_key(sheet_id).sheet1
        ws.clear()
        ws.update(values=rows, range_name="A1", value_input_option="USER_ENTERED")
        print(f"Pushed {len(df)} rows to sheet for {table}")
