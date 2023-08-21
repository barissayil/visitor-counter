import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("visitor_count")


def handler(event, context):
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET",
        "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        "Content-Type": "application/json",
    }

    try:
        response = table.get_item(Key={"id": "visitor_count"})

        count = int(response.get("Item", {}).get("count", 0))
        new_count = count + 1

        table.put_item(Item={"id": "visitor_count", "count": new_count})

        return {
            "statusCode": 200,
            "headers": cors_headers,
            "body": json.dumps({"visitor_count": new_count}),
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": cors_headers,
            "body": json.dumps(
                {"error": f"Failed to update visitor count. Detail: {str(e)}"}
            ),
        }
