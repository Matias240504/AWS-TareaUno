import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Función Lambda para contar visitas al sitio web AWS Demo
    
    Esta función puede ser invocada desde:
    - API Gateway (HTTP request)
    - Directamente desde JavaScript (con credenciales)
    - Otros servicios AWS
    """
    
    print(f"📊 Lambda function invoked at {datetime.now()}")
    print(f"🔍 Event: {json.dumps(event)}")
    
    try:
        # Obtener acción del evento (increment, get, reset)
        if 'body' in event and event['body']:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
            action = body.get('action', 'get')
        else:
            action = event.get('action', 'get')
        
        print(f"🎯 Action requested: {action}")
        
        # Simular almacenamiento de contador (en producción usar DynamoDB)
        # Por simplicidad, usar un valor estático que se incrementa
        
        if action == 'increment':
            # Incrementar contador
            new_count = increment_counter()
            
            response = {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'success': True,
                    'count': new_count,
                    'message': 'Counter incremented successfully',
                    'timestamp': datetime.now().isoformat()
                })
            }
            
        elif action == 'get':
            # Obtener contador actual
            current_count = get_counter()
            
            response = {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'success': True,
                    'count': current_count,
                    'message': 'Counter retrieved successfully',
                    'timestamp': datetime.now().isoformat()
                })
            }
            
        elif action == 'reset':
            # Resetear contador (solo para testing)
            reset_count = reset_counter()
            
            response = {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'success': True,
                    'count': reset_count,
                    'message': 'Counter reset successfully',
                    'timestamp': datetime.now().isoformat()
                })
            }
            
        else:
            # Acción no válida
            response = {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Invalid action',
                    'message': 'Supported actions: get, increment, reset',
                    'timestamp': datetime.now().isoformat()
                })
            }
        
        print(f"✅ Response: {response}")
        return response
        
    except Exception as e:
        print(f"❌ Error in Lambda function: {str(e)}")
        
        error_response = {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Internal server error',
                'message': str(e),
                'timestamp': datetime.now().isoformat()
            })
        }
        
        return error_response

def get_counter():
    """
    Obtener el valor actual del contador
    En producción, esto leería de DynamoDB
    """
    # Simulación: en la realidad usarías DynamoDB
    # dynamodb = boto3.resource('dynamodb')
    # table = dynamodb.Table('visit-counter')
    # response = table.get_item(Key={'id': 'visits'})
    # return response.get('Item', {}).get('count', 0)
    
    # Por ahora, simular con un valor base
    import random
    base_count = 100
    return base_count + random.randint(1, 50)

def increment_counter():
    """
    Incrementar el contador de visitas
    En producción, esto actualizaría DynamoDB
    """
    # Simulación: en la realidad usarías DynamoDB
    # dynamodb = boto3.resource('dynamodb')
    # table = dynamodb.Table('visit-counter')
    # response = table.update_item(
    #     Key={'id': 'visits'},
    #     UpdateExpression='ADD #count :val',
    #     ExpressionAttributeNames={'#count': 'count'},
    #     ExpressionAttributeValues={':val': 1},
    #     ReturnValues='UPDATED_NEW'
    # )
    # return response['Attributes']['count']
    
    # Por ahora, simular incremento
    current = get_counter()
    return current + 1

def reset_counter():
    """
    Resetear el contador (solo para testing)
    """
    # En producción, esto resetearía DynamoDB
    # dynamodb = boto3.resource('dynamodb')
    # table = dynamodb.Table('visit-counter')
    # table.put_item(Item={'id': 'visits', 'count': 0})
    
    return 0

# Función para manejar OPTIONS (CORS preflight)
def handle_options():
    """
    Manejar requests OPTIONS para CORS
    """
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '86400'
        },
        'body': ''
    }

# Para testing local
if __name__ == "__main__":
    # Test events
    test_events = [
        {'action': 'get'},
        {'action': 'increment'},
        {'action': 'reset'}
    ]
    
    print("🧪 Testing Lambda function locally...")
    
    for event in test_events:
        print(f"\n📝 Testing event: {event}")
        result = lambda_handler(event, None)
        print(f"📤 Result: {result}")
