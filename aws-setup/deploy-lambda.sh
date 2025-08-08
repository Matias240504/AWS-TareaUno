#!/bin/bash

# Script para desplegar función Lambda y crear tabla DynamoDB
# Configuración
FUNCTION_NAME="visit-counter-lambda"
TABLE_NAME="visit-counter"
ROLE_NAME="lambda-visit-counter-role"
POLICY_NAME="lambda-visit-counter-policy"
REGION="us-east-1"
LAMBDA_DIR="../lambda"

echo "🚀 Desplegando función Lambda para contador de visitas..."

# Verificar que AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI no está configurado. Ejecuta 'aws configure' primero."
    exit 1
fi

echo "✅ AWS CLI configurado correctamente"

# 1. Crear tabla DynamoDB
echo "📊 Creando tabla DynamoDB: $TABLE_NAME"
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
    --key-schema \
        AttributeName=id,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Tabla DynamoDB creada exitosamente"
else
    echo "ℹ️  Tabla DynamoDB ya existe o error en creación"
fi

# Esperar a que la tabla esté activa
echo "⏳ Esperando a que la tabla esté activa..."
aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION

# 2. Crear política IAM para Lambda
echo "🔐 Creando política IAM para Lambda"
POLICY_DOCUMENT='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": "arn:aws:dynamodb:'$REGION':*:table/'$TABLE_NAME'"
        }
    ]
}'

aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document "$POLICY_DOCUMENT" \
    --description "Policy for Lambda visit counter function" 2>/dev/null

# 3. Crear rol IAM para Lambda
echo "👤 Creando rol IAM para Lambda"
TRUST_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document "$TRUST_POLICY" \
    --description "Role for Lambda visit counter function" 2>/dev/null

# 4. Adjuntar política al rol
echo "🔗 Adjuntando política al rol"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

# Adjuntar política básica de Lambda
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

# 5. Esperar a que el rol se propague
echo "⏳ Esperando propagación del rol IAM..."
sleep 10

# 6. Preparar código Lambda
echo "📦 Preparando código Lambda"
cd $LAMBDA_DIR

# Instalar dependencias si no existen
if [ ! -d "node_modules" ]; then
    echo "📥 Instalando dependencias de Node.js"
    npm install
fi

# Crear archivo ZIP
echo "🗜️  Creando archivo ZIP"
zip -r ../lambda-function.zip . -x "*.git*" "*.DS_Store*"
cd ..

# 7. Crear o actualizar función Lambda
echo "⚡ Creando función Lambda"
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

# Intentar crear la función
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime nodejs18.x \
    --role $ROLE_ARN \
    --handler visit-counter.handler \
    --zip-file fileb://lambda-function.zip \
    --description "Visit counter function with DynamoDB" \
    --timeout 30 \
    --memory-size 128 \
    --environment Variables="{DYNAMODB_TABLE_NAME=$TABLE_NAME,AWS_REGION=$REGION}" \
    --region $REGION 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Función Lambda creada exitosamente"
else
    echo "🔄 Función ya existe, actualizando código..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://lambda-function.zip \
        --region $REGION
    
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --environment Variables="{DYNAMODB_TABLE_NAME=$TABLE_NAME,AWS_REGION=$REGION}" \
        --region $REGION
    
    echo "✅ Función Lambda actualizada exitosamente"
fi

# 8. Limpiar archivo temporal
rm -f lambda-function.zip

# 9. Probar la función
echo "🧪 Probando función Lambda"
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload '{"action":"get"}' \
    --region $REGION \
    response.json

if [ -f response.json ]; then
    echo "📋 Respuesta de la función:"
    cat response.json
    echo ""
    rm response.json
fi

echo ""
echo "🎉 ¡Despliegue completado!"
echo "📝 Información importante:"
echo "   - Función Lambda: $FUNCTION_NAME"
echo "   - Tabla DynamoDB: $TABLE_NAME"
echo "   - Región: $REGION"
echo "   - ARN de la función: arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME"
echo ""
echo "🔧 Para usar en tu aplicación, actualiza las variables de entorno:"
echo "   LAMBDA_FUNCTION_NAME=$FUNCTION_NAME"
echo "   DYNAMODB_TABLE_NAME=$TABLE_NAME"
