import os
import json
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
import psycopg2
import psycopg2.extras

def handle_s3_test(event, context):
    bucket = os.environ.get("S3_BUCKET")
    if not bucket:
        return {
            "success": False,
            "error": "S3_BUCKET environment variable not set"
        }
    s3 = boto3.client("s3")
    try:
        # Check if bucket exists by attempting to list objects
        resp = s3.list_objects_v2(Bucket=bucket, MaxKeys=10)
        files = [obj["Key"] for obj in resp.get("Contents", [])]
        return {
            "bucket": bucket,
            "success": True,
            "files": files,
            "error": None
        }
    except ClientError as e:
        return {
            "bucket": bucket,
            "success": False,
            "files": [],
            "error": str(e)
        }
    except NoCredentialsError:
        return {
            "bucket": bucket,
            "success": False,
            "files": [],
            "error": "AWS credentials not found"
        }
    except Exception as e:
        return {
            "bucket": bucket,
            "success": False,
            "files": [],
            "error": str(e)
        }

def handle_rds_test(event, context):
    dsn = os.environ.get("DB_DSN")
    if not dsn:
        return {
            "success": False,
            "error": "DB_DSN environment variable not set"
        }
    try:
        conn = psycopg2.connect(dsn)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT version() as db_version;")
        row = cur.fetchone()
        cur.close()
        conn.close()
        return {
            "success": True,
            "db_version": row["db_version"] if row else None,
            "error": None
        }
    except psycopg2.Error as e:
        return {
            "success": False,
            "db_version": None,
            "error": str(e)
        }
    except Exception as e:
        return {
            "success": False,
            "db_version": None,
            "error": str(e)
        }

import logging

def lambda_handler(event, context):
    # Log the event for debugging
    logging.warning("EVENT: %s", json.dumps(event))
    # Use rawPath if available (HTTP API v2.0), else fallback to path
    path = event.get("rawPath") or event.get("path", "")
    # Remove stage prefix if present
    stage = event.get("requestContext", {}).get("stage")
    if stage and path.startswith(f"/{stage}"):
        path = path[len(stage)+1:] if path.startswith(f"/{stage}/") else "/"

    status_code = 200
    response_body = {}

    if path == "/api/s3-test":
        response_body = handle_s3_test(event, context)
    elif path == "/api/rds-test":
        response_body = handle_rds_test(event, context)
    elif path == "/healthz":
        response_body = {"status": "ok"}
    else:
        status_code = 404
        response_body = {"error": "Not Found"}

    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_body)
    }
