import json
import boto3
import decimal
import logging
import os

tablename = 'gselector'
queue_url = 'https://sqs.ap-south-1.amazonaws.com/169318795497/mysqs'
#number_sends= 10

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(tablename)
sqs = boto3.client('sqs')

def lambda_handler(event, context):
    data = table.scan()['Items']
    for i in data:
        response = sqs.send_message(QueueUrl=queue_url, MessageBody=(json.dumps(i)))
    print(f'{len(data)} - messages have been sent to SQS')
