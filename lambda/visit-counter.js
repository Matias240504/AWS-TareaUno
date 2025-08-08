const AWS = require('aws-sdk');

// Configurar DynamoDB
const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: process.env.AWS_REGION || 'us-east-1'
});

const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME || 'visit-counter';

exports.handler = async (event) => {
    console.log('Lambda function invoked:', JSON.stringify(event, null, 2));
    
    try {
        const action = event.action || 'increment';
        
        switch (action) {
            case 'increment':
                return await incrementCounter();
            case 'get':
                return await getCounter();
            case 'reset':
                return await resetCounter();
            default:
                return {
                    statusCode: 400,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type'
                    },
                    body: JSON.stringify({
                        success: false,
                        message: 'Invalid action. Use: increment, get, or reset'
                    })
                };
        }
    } catch (error) {
        console.error('Error in Lambda function:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                message: 'Internal server error',
                error: error.message
            })
        };
    }
};

async function incrementCounter() {
    try {
        const params = {
            TableName: TABLE_NAME,
            Key: { id: 'visit-counter' },
            UpdateExpression: 'ADD #count :inc, #totalVisits :inc SET #lastUpdated = :timestamp',
            ExpressionAttributeNames: {
                '#count': 'count',
                '#totalVisits': 'totalVisits',
                '#lastUpdated': 'lastUpdated'
            },
            ExpressionAttributeValues: {
                ':inc': 1,
                ':timestamp': new Date().toISOString()
            },
            ReturnValues: 'ALL_NEW'
        };

        const result = await dynamodb.update(params).promise();
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                data: {
                    count: result.Attributes.count,
                    totalVisits: result.Attributes.totalVisits,
                    lastUpdated: result.Attributes.lastUpdated
                },
                message: 'Counter incremented successfully'
            })
        };
    } catch (error) {
        console.error('Error incrementing counter:', error);
        throw error;
    }
}

async function getCounter() {
    try {
        const params = {
            TableName: TABLE_NAME,
            Key: { id: 'visit-counter' }
        };

        const result = await dynamodb.get(params).promise();
        
        if (!result.Item) {
            // Inicializar contador si no existe
            const initParams = {
                TableName: TABLE_NAME,
                Item: {
                    id: 'visit-counter',
                    count: 0,
                    totalVisits: 0,
                    createdAt: new Date().toISOString(),
                    lastUpdated: new Date().toISOString()
                }
            };
            
            await dynamodb.put(initParams).promise();
            
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: true,
                    data: {
                        count: 0,
                        totalVisits: 0,
                        lastUpdated: new Date().toISOString()
                    },
                    message: 'Counter initialized'
                })
            };
        }

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                data: {
                    count: result.Item.count || 0,
                    totalVisits: result.Item.totalVisits || 0,
                    lastUpdated: result.Item.lastUpdated
                },
                message: 'Counter retrieved successfully'
            })
        };
    } catch (error) {
        console.error('Error getting counter:', error);
        throw error;
    }
}

async function resetCounter() {
    try {
        const params = {
            TableName: TABLE_NAME,
            Key: { id: 'visit-counter' },
            UpdateExpression: 'SET #count = :zero, #lastUpdated = :timestamp',
            ExpressionAttributeNames: {
                '#count': 'count',
                '#lastUpdated': 'lastUpdated'
            },
            ExpressionAttributeValues: {
                ':zero': 0,
                ':timestamp': new Date().toISOString()
            },
            ReturnValues: 'ALL_NEW'
        };

        const result = await dynamodb.update(params).promise();
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                data: {
                    count: result.Attributes.count,
                    totalVisits: result.Attributes.totalVisits || 0,
                    lastUpdated: result.Attributes.lastUpdated
                },
                message: 'Counter reset successfully'
            })
        };
    } catch (error) {
        console.error('Error resetting counter:', error);
        throw error;
    }
}
