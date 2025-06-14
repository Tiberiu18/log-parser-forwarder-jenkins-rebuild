import requests
import json
import argparse
import re
import os
import time
from prometheus_client import Counter, start_http_server
# Start /metrics at port 8000
start_http_server(8000) # runs in a separate thread
print("[INIT] Metrics server setup :8000; starting parsing loop...")

batches_sent = Counter("batches_sent_total", "Log batches successfully sent")

parser_errors = Counter("parser_errors_total", "Errors encountered by the parser")


def readLogFile(filename):
    with open(filename,"r") as logf:
        content = logf.read()
        return content

def createListFromContent(content):
    #Split lines with newline as separator
    listOfLines=re.split(r'[\n]', content)
    return listOfLines

def filterLinesForError(listOfLines):
    filtered_lines = []
    for line in listOfLines:
        if "critical" in line.lower() or "error" in line.lower():
            filtered_lines.append(line)
    listOfLines.clear()
    return filtered_lines



def createBatchesOfTen(content):
    listOfLines_raw=createListFromContent(content)
    listOfLines_filtered = filterLinesForError(listOfLines_raw)
    listOfBatches = []
    count = 0
    batch=[]
    for line in listOfLines_filtered:
        batch.append(line)
        count=count+1
        if count == 10:
            listOfBatches.append(batch.copy())
            batch.clear()
            count = 0
    # Means the last batch will have a length lesser than 10, we do not want to skip these
    if len(batch) > 0:
        listOfBatches.append(batch.copy())
        batch.clear()
    return listOfBatches

def sendBatch(URL,listOfBatches):
    payload = {"logs": listOfBatches}
    headers = {'Content-Type':'application/json'}
    try:
        response = requests.post(URL, json=payload, headers=headers, timeout=5)
        # What is this for? Well, if status code is 200-299, won't do anything
        # If it is 400-599, raises an exception requests.HTTPERROR
        response.raise_for_status()
        batches_sent.inc()
        print("Batch sent successfully.")
        return response
    except requests.exceptions.RequestException as exc:
        parser_errors.inc()
        print(f"[ERROR] Batch failed: {exc}")
        raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Log parsing and forwarding")
    parser.add_argument("logfile")
    arguments = parser.parse_args()
    logfile = arguments.logfile
    URL = os.getenv("API_URL", "http://log-receiver-api:3000/logs")
    while True:
        try:
            logfile_content = readLogFile(logfile)
            listOfBatches = createBatchesOfTen(logfile_content)
            response = sendBatch(URL,listOfBatches)
            print(response.text)
        except Exception as ex:
            # We already have parser_errors.inc(), so we'll just log now
            print("[MAIN] Unhandled error:", exc)
        time.sleep(60)
