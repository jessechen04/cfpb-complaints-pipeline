FROM python:3.12-slim

# Flush print() output straight to Cloud Logging
ENV PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copies main.py and sql/tables/ (anything listed in .gcloudignore never gets here)
COPY . .

CMD ["python", "main.py"]
