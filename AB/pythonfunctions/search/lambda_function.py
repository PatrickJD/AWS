import json
import requests
import boto3
import os
from elasticsearch import Elasticsearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

url = os.environ.get("SEARCH_ENDPOINT", None)


# Process DynamoDB Stream records and insert the object in ElasticSearch
# Use the Table name as index and doc_type name
# Force index refresh upon all actions for close to realtime reindexing
# Use IAM Role for authentication
# Properly unmarshal DynamoDB JSON types. Binary NOT tested.

def lambda_handler(event, context):
    
    session = boto3.session.Session()
    credentials = session.get_credentials()

    # Get proper credentials for ES auth
    awsauth = AWS4Auth(credentials.access_key,
                       credentials.secret_key,
                       session.region_name, 'es',
                       session_token=credentials.token)
    # Put the user query into the query DSL for more accurate search results.
    # Note that certain fields are boosted (^).
    query = {
        "size": 25,
        "query": {
            "query_string": {
                "query": "*" + event['queryStringParameters']['q'] + "*",
                "fields": ["DetectedObjects.Labels.Name", "DetectedFaces.FaceDetails.Gender.Value", "DetectedText.TextDetections.DetectedText"]
            }
        }
    }

    # ES 6.x requires an explicit Content-Type header
    headers = { "Content-Type": "application/json" }

    # Make the signed HTTP request
    r = requests.get(url, auth=awsauth, headers=headers, data=json.dumps(query))

    print(r.text)

    # Create the response and add some extra content to support CORS
    response = {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": '*'
        },
        "isBase64Encoded": False
    }

    # Add the search results to the response
    response['body'] = r.text
    return response