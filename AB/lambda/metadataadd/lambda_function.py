from decimal import Decimal

import boto3
import os
import json
import time
import datetime

DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", None)
cfdistro = os.environ.get("CLOUDFRONT_DISTRO", None)
dynamodb = boto3.resource("dynamodb")
dynamodb_table = dynamodb.Table(DYNAMODB_TABLE)

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        rekognition = boto3.client("rekognition")
        objectdetections = rekognition.detect_labels(
            Image={
                "S3Object": {
                    "Bucket": bucket,
                    "Name": key,
                }
            },
            MaxLabels=10,
            MinConfidence=90,
        )
        
        objectdetectionsload = json.loads(json.dumps(objectdetections), parse_float=Decimal)

        textdetections = rekognition.detect_text(
            Image={
                "S3Object": {
                    "Bucket": bucket,
                    "Name": key,
                }
            }
        )

        textdetectionsload = json.loads(json.dumps(textdetections), parse_float=Decimal)

        imgurl = cfdistro+key
        unixtime = time.time_ns()
        dt = time.strftime("%Z - %Y/%m/%d, %H:%M:%S", time.gmtime(time.time()))

        dynamodb_table.put_item(Item={
            "ImageId": key,
            "LastUpdated" : unixtime,
            "LastUpdatedTimestamp" : dt,
            "ImageURL": imgurl,
            "DetectedObjects": objectdetectionsload,
            "DetectedText": textdetectionsload,
            "ManualTags": "",
            "License": "Public",
            "ObjLock": "Open",
            "Version": "1.0"
        })