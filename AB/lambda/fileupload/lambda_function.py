import json
import boto3
import base64
import uuid
import os

s3 = boto3.client('s3')
randomname = str(uuid.uuid4())
S3BUCKET = os.environ.get("S3_BUCKET", None)

def lambda_handler(event, context):
    if event['httpMethod'] == 'POST' : 
        data = json.loads(event['body'])
        name = data['name']
        extension = os.path.splitext(name)[1]
        filename = randomname+extension
        image = data['file']
        image = image[image.find(",")+1:]
        dec = base64.b64decode(image + "===")
        s3.put_object(Bucket=S3BUCKET, Key=filename, Body=dec)
        return {'statusCode': 200, 'body': json.dumps({'message': 'successful lambda function call'}), 'headers': {'Access-Control-Allow-Origin': '*'}}