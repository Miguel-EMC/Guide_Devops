import json

def lambda_handler(event, context):
    """
    Sample Lambda function that echoes the incoming event.
    """
    print(f"Received event: {event}")

    # Example: Check for a query parameter
    name = "World"
    if event.get('queryStringParameters') and event['queryStringParameters'].get('name'):
        name = event['queryStringParameters']['name']
    elif event.get('body'):
        try:
            body = json.loads(event['body'])
            if body.get('name'):
                name = body['name']
        except json.JSONDecodeError:
            pass

    response_body = {
        "message": f"Hello, {name} from Serverless API!",
        "input": event
    }

    return {
        "statusCode": 200,
        "body": json.dumps(response_body),
        "headers": {
            "Content-Type": "application/json"
        }
    }
