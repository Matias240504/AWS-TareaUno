#!/bin/bash
# Script automatizado para desplegar AWS Demo en servicios reales de AWS

set -e  # Salir si cualquier comando falla

echo "🚀 Iniciando despliegue automatizado en AWS..."
echo "================================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Verificar prerrequisitos
log "Verificando prerrequisitos..."

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    error "AWS CLI no está instalado. Instálalo primero."
fi

# Verificar configuración AWS
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS CLI no está configurado. Ejecuta 'aws configure' primero."
fi

# Variables
REGION=${AWS_REGION:-us-east-1}
BUCKET_NAME="aws-demo-$(date +%s)-$(whoami | tr '[:upper:]' '[:lower:]')"
KEY_NAME="aws-demo-key-$(date +%s)"
SECURITY_GROUP_NAME="aws-demo-sg-$(date +%s)"
INSTANCE_NAME="AWS-Demo-NodeJS-$(date +%s)"

log "Configuración del despliegue:"
echo "  - Región: $REGION"
echo "  - Bucket S3: $BUCKET_NAME"
echo "  - Key Pair: $KEY_NAME"
echo "  - Security Group: $SECURITY_GROUP_NAME"
echo "  - Instancia: $INSTANCE_NAME"

read -p "¿Continuar con el despliegue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Despliegue cancelado."
    exit 0
fi

# Paso 1: Crear Key Pair
log "Paso 1: Creando Key Pair para EC2..."
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > ${KEY_NAME}.pem

chmod 400 ${KEY_NAME}.pem
log "✅ Key Pair creado: ${KEY_NAME}.pem"

# Paso 2: Crear Security Group
log "Paso 2: Creando Security Group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for AWS Demo NodeJS" \
    --query 'GroupId' \
    --output text)

# Configurar reglas de seguridad
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0

log "✅ Security Group creado: $SECURITY_GROUP_ID"

# Paso 3: Crear Bucket S3
log "Paso 3: Creando Bucket S3..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Actualizar política del bucket con el nombre real
sed "s/BUCKET_NAME/$BUCKET_NAME/g" aws-setup/s3-bucket-policy.json > /tmp/s3-policy.json

# Aplicar política pública
aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file:///tmp/s3-policy.json

# Subir archivos estáticos
log "Subiendo archivos a S3..."
if [ -d "assets" ]; then
    aws s3 cp assets/ s3://$BUCKET_NAME/assets/ --recursive
fi

if [ -d "public" ]; then
    aws s3 cp public/ s3://$BUCKET_NAME/public/ --recursive
fi

log "✅ Bucket S3 creado y configurado: $BUCKET_NAME"

# Paso 4: Lanzar Instancia EC2
log "Paso 4: Lanzando instancia EC2..."

# Obtener AMI ID más reciente de Ubuntu 22.04
AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

log "Usando AMI: $AMI_ID"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

log "✅ Instancia EC2 lanzada: $INSTANCE_ID"

# Esperar a que la instancia esté running
log "Esperando a que la instancia esté lista..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

log "✅ Instancia lista. IP pública: $PUBLIC_IP"

# Paso 5: Crear función Lambda (opcional)
log "Paso 5: Creando función Lambda..."

# Obtener Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Crear rol para Lambda
ROLE_ARN=$(aws iam create-role \
    --role-name lambda-execution-role-$(date +%s) \
    --assume-role-policy-document file://aws-setup/lambda-trust-policy.json \
    --query 'Role.Arn' \
    --output text)

# Adjuntar política básica
aws iam attach-role-policy \
    --role-name $(basename $ROLE_ARN) \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Esperar a que el rol se propague
sleep 10

# Crear ZIP de la función Lambda
cd aws-setup
zip -r ../lambda-function.zip lambda-function.py
cd ..

# Crear función Lambda
LAMBDA_ARN=$(aws lambda create-function \
    --function-name aws-demo-counter-$(date +%s) \
    --runtime python3.9 \
    --role $ROLE_ARN \
    --handler lambda-function.lambda_handler \
    --zip-file fileb://lambda-function.zip \
    --query 'FunctionArn' \
    --output text)

log "✅ Función Lambda creada: $LAMBDA_ARN"

# Paso 6: Crear archivo de configuración para la instancia
log "Paso 6: Preparando configuración para EC2..."

cat > deploy-config.env << EOF
PORT=3000
NODE_ENV=production
EC2_INSTANCE_ID=$INSTANCE_ID
EC2_PUBLIC_IP=$PUBLIC_IP
AWS_REGION=$REGION
S3_BUCKET_NAME=$BUCKET_NAME
LAMBDA_FUNCTION_ARN=$LAMBDA_ARN
VISIT_COUNTER=0
EOF

# Crear script de despliegue remoto
cat > remote-deploy.sh << 'EOF'
#!/bin/bash
# Script que se ejecutará en la instancia EC2

set -e

echo "🔧 Configurando instancia EC2..."

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs git nginx

# Instalar PM2
sudo npm install -g pm2

# Configurar Nginx
sudo tee /etc/nginx/sites-available/aws-demo > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX_EOF

sudo ln -sf /etc/nginx/sites-available/aws-demo /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configurar firewall
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw --force enable

echo "✅ Instancia EC2 configurada correctamente"
EOF

chmod +x remote-deploy.sh

log "Esperando a que SSH esté disponible..."
sleep 30

# Intentar conexión SSH con reintentos
for i in {1..10}; do
    if ssh -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$PUBLIC_IP "echo 'SSH conectado'" 2>/dev/null; then
        log "✅ Conexión SSH establecida"
        break
    else
        warn "Intento $i/10: Esperando conexión SSH..."
        sleep 30
    fi
    
    if [ $i -eq 10 ]; then
        error "No se pudo establecer conexión SSH"
    fi
done

# Subir archivos a la instancia
log "Subiendo archivos a la instancia EC2..."
scp -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no -r . ubuntu@$PUBLIC_IP:~/aws-demo-nodejs/
scp -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no deploy-config.env ubuntu@$PUBLIC_IP:~/aws-demo-nodejs/.env
scp -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no remote-deploy.sh ubuntu@$PUBLIC_IP:~/

# Ejecutar configuración remota
log "Ejecutando configuración en la instancia EC2..."
ssh -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP "chmod +x ~/remote-deploy.sh && ~/remote-deploy.sh"

# Instalar dependencias y iniciar aplicación
log "Instalando dependencias y iniciando aplicación..."
ssh -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP << 'REMOTE_EOF'
cd ~/aws-demo-nodejs
npm install
pm2 start server.js --name "aws-demo-nodejs"
pm2 startup
pm2 save
REMOTE_EOF

# Resumen final
log "🎉 ¡Despliegue completado exitosamente!"
echo "================================================"
echo -e "${BLUE}📋 Información del despliegue:${NC}"
echo "  🌐 URL de la aplicación: http://$PUBLIC_IP"
echo "  📊 Health Check: http://$PUBLIC_IP/api/health"
echo "  ☁️  AWS Info: http://$PUBLIC_IP/api/aws-info"
echo "  📈 Counter: http://$PUBLIC_IP/api/counter"
echo ""
echo -e "${BLUE}🔧 Recursos creados:${NC}"
echo "  📦 Instancia EC2: $INSTANCE_ID"
echo "  🗄️  Bucket S3: $BUCKET_NAME"
echo "  🔑 Key Pair: ${KEY_NAME}.pem"
echo "  🛡️  Security Group: $SECURITY_GROUP_ID"
echo "  ⚡ Lambda: $LAMBDA_ARN"
echo ""
echo -e "${BLUE}💻 Comandos útiles:${NC}"
echo "  🔗 Conectar SSH: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
echo "  📋 Ver logs: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP 'pm2 logs aws-demo-nodejs'"
echo "  🔄 Reiniciar: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP 'pm2 restart aws-demo-nodejs'"
echo ""
echo -e "${YELLOW}💰 Recuerda: Estos recursos pueden generar costos. Para limpiar:${NC}"
echo "  ./cleanup-aws.sh"

# Guardar información del despliegue
cat > deployment-info.txt << EOF
Despliegue AWS Demo - $(date)
================================

URL: http://$PUBLIC_IP
Instancia EC2: $INSTANCE_ID
Bucket S3: $BUCKET_NAME
Key Pair: ${KEY_NAME}.pem
Security Group: $SECURITY_GROUP_ID
Lambda: $LAMBDA_ARN

Comandos:
- SSH: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP
- Logs: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP 'pm2 logs aws-demo-nodejs'
- Reiniciar: ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP 'pm2 restart aws-demo-nodejs'
EOF

log "📄 Información guardada en: deployment-info.txt"
