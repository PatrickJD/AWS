from decimal import Decimal

import boto3
import os
import json

DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", None)
dynamodb = boto3.resource("dynamodb")
dynamodb_table = dynamodb.Table(DYNAMODB_TABLE)

def lambda_handler(event, context):
    for record in event['Records']:
        key = record['s3']['object']['key']

        dynamodb_table.delete_item(Key={
            "image-id": key,
        })