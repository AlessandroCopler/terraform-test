

def lambda_handler(event, context):
    print(event)
    print(context)
    return 'Hello from Lambda!'