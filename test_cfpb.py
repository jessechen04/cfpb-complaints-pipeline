import json

prev = None
violations = 0
with open("complaints_raw.jsonl", encoding="utf-8") as f:
    for i, line in enumerate(f, 1):
        d = json.loads(line)["date_received"]
        if prev is not None and d > prev:
            violations += 1
            if violations <= 5:
                print(f"line {i}: {d} is newer than previous {prev}")
        prev = d

print("Order violations:", violations)