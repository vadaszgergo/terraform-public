import json
import urllib.request
import time

def lambda_handler(event, context):
    try:
        # Add a small delay to ensure the Lambda has time to warm up
        time.sleep(1)
        
        # Get the public IP
        response = urllib.request.urlopen('https://ifconfig.me/ip', timeout=5)
        public_ip = response.read().decode('utf-8').strip()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Success',
                'public_ip': public_ip
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error',
                'error': str(e)
            })
        } 