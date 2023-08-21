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
        response = table.update_item(
            Key={"id": "visitor_count"},
            UpdateExpression="SET #count = if_not_exists(#count, :zero) + :increment_value",
            ExpressionAttributeNames={"#count": "count"},
            ExpressionAttributeValues={":increment_value": 1, ":zero": 0},
            ReturnValues="UPDATED_NEW",
        )

        visitor_count = int(response["Attributes"]["count"])

        return {
            "statusCode": 200,
            "headers": cors_headers,
            "body": json.dumps({"visitor_count": visitor_count}),
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
