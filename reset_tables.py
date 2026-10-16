from pathlib import Path
from google.cloud import bigquery

sql = (Path(__file__).parent / "sql" / "tables" / "drop_tables.sql").read_text()

if input("Drop all pipeline tables? Type 'yes': ") == "yes":
    bigquery.Client(project="cfpb-complaints-pipeline").query(sql).result()
    print("Dropped.")