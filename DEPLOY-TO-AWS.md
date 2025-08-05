# 🚀 Guía de Despliegue AWS Real

## Prerrequisitos

### 1. Cuenta AWS
- Crear cuenta AWS gratuita en https://aws.amazon.com/free/
- Configurar método de pago (capa gratuita disponible)

### 2. AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

### 3. Crear usuario IAM
1. Ir a AWS Console → IAM → Users
2. Crear usuario: `aws-demo-user`
3. Adjuntar políticas:
   - `AmazonEC2FullAccess`
   - `AmazonS3FullAccess`
   - `IAMFullAccess`
   - `AWSLambdaFullAccess`
4. Crear Access Key y Secret Key

## 📋 Pasos de Despliegue

### Paso 1: Crear Key Pair para EC2
```bash
aws ec2 create-key-pair --key-name aws-demo-key --query 'KeyMaterial' --output text > aws-demo-key.pem
chmod 400 aws-demo-key.pem
```

### Paso 2: Crear Security Group
```bash
aws ec2 create-security-group --group-name aws-demo-sg --description "Security group for AWS Demo"
aws ec2 authorize-security-group-ingress --group-name aws-demo-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name aws-demo-sg --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name aws-demo-sg --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name aws-demo-sg --protocol tcp --port 3000 --cidr 0.0.0.0/0
```

### Paso 3: Lanzar Instancia EC2
```bash
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --count 1 \
  --instance-type t2.micro \
  --key-name aws-demo-key \
  --security-groups aws-demo-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=AWS-Demo-NodeJS}]'
```

### Paso 4: Crear Bucket S3
```bash
# Crear bucket (nombre debe ser único globalmente)
BUCKET_NAME="aws-demo-$(date +%s)-$(whoami)"
aws s3 mb s3://$BUCKET_NAME

# Configurar política pública
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://aws-setup/s3-bucket-policy.json

# Subir archivos
aws s3 cp assets/ s3://$BUCKET_NAME/assets/ --recursive
aws s3 cp public/ s3://$BUCKET_NAME/public/ --recursive
```

### Paso 5: Crear Función Lambda
```bash
# Crear rol para Lambda
aws iam create-role --role-name lambda-execution-role --assume-role-policy-document file://aws-setup/lambda-trust-policy.json

# Adjuntar política
aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Crear función Lambda
zip lambda-function.zip aws-setup/lambda-function.py
aws lambda create-function \
  --function-name aws-demo-counter \
  --runtime python3.9 \
  --role arn:aws:iam::ACCOUNT-ID:role/lambda-execution-role \
  --handler lambda-function.lambda_handler \
  --zip-file fileb://lambda-function.zip
```

### Paso 6: Conectar a EC2 y Desplegar
```bash
# Obtener IP pública
INSTANCE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=AWS-Demo-NodeJS" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

# Conectar por SSH
ssh -i aws-demo-key.pem ubuntu@$INSTANCE_IP

# En la instancia EC2:
sudo apt update
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs git

# Clonar proyecto
git clone https://github.com/tu-usuario/aws-demo-nodejs.git
cd aws-demo-nodejs

# Ejecutar script de setup
chmod +x aws-setup/ec2-nodejs-setup.sh
./aws-setup/ec2-nodejs-setup.sh

# Configurar variables de entorno
cp .env.example .env
# Editar .env con valores reales de AWS

# Desplegar aplicación
./deploy-nodejs-app.sh
```

## 🔧 Configuración Post-Despliegue

### Variables de Entorno (.env)
```bash
PORT=3000
NODE_ENV=production
EC2_INSTANCE_ID=i-xxxxxxxxx
EC2_PUBLIC_IP=xx.xx.xx.xx
AWS_REGION=us-east-1
S3_BUCKET_NAME=tu-bucket-name
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
```

### Verificar Servicios
- **Web**: http://EC2_PUBLIC_IP
- **API Health**: http://EC2_PUBLIC_IP/api/health
- **S3 Files**: http://EC2_PUBLIC_IP/api/s3/files

## 💰 Costos Estimados (Capa Gratuita)
- **EC2 t2.micro**: 750 horas/mes gratis
- **S3**: 5GB almacenamiento gratis
- **Lambda**: 1M invocaciones gratis
- **Transferencia**: 15GB salida gratis

## 🛠️ Comandos Útiles
```bash
# Ver logs de la aplicación
pm2 logs aws-demo-nodejs

# Reiniciar aplicación
pm2 restart aws-demo-nodejs

# Ver estado de servicios
sudo systemctl status nginx
pm2 status

# Actualizar aplicación
git pull origin main
npm install
pm2 restart aws-demo-nodejs
```

## 🚨 Limpieza (Para evitar costos)
```bash
# Terminar instancia EC2
aws ec2 terminate-instances --instance-ids i-xxxxxxxxx

# Eliminar bucket S3
aws s3 rb s3://tu-bucket-name --force

# Eliminar función Lambda
aws lambda delete-function --function-name aws-demo-counter

# Eliminar security group
aws ec2 delete-security-group --group-name aws-demo-sg
```
