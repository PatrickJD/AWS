from decimal import Decimal

import boto3
import os

DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", None)
dynamodb = boto3.resource("dynamodb")
dynamodb_table = dynamodb.Table(DYNAMODB_TABLE)

# Consider using UpdateItem API instead of PutItem.  Store items in a list or store the entire JSON response so we aren't creating too many items.
# 

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        rekognition = boto3.client("rekognition")
        response = rekognition.detect_labels(
            Image={
                "S3Object": {
                    "Bucket": bucket,
                    "Name": key,
                }
            },
            MaxLabels=10,
            MinConfidence=96,
        )

        labels = response.get('Labels', None)

        for label in labels:
            dynamodb_table.update_item(Item={
                "image-id": key,
                "tag": label['Name'],
                "conf": Decimal(label['Confidence'])
            })