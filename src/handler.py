import os

def lambda_handler(event, context):
    env = os.environ.get("ENV", "undefined")
    return {
        "statusCode": 200,
        "body": f"Hello from Lambda in '{env}' environment!"
    }
