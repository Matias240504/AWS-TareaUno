#!/bin/bash
# deploy-infrastructure.sh

# Configuración
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_CIDR="10.0.2.0/24"
REGION="us-east-1"

# Crear VPC
echo "Creando VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --query 'Vpc.VpcId' \
  --output text)

# Crear Subredes
echo "Creando subred pública..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_CIDR \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Creando subred privada..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_CIDR \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

# Crear Internet Gateway
echo "Creando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

# Asociar IGW a VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $REGION

# Configurar tabla de rutas
echo "Configurando tabla de rutas..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION

# Asociar subred pública a la tabla de rutas
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_ID \
  --route-table-id $ROUTE_TABLE_ID \
  --region $REGION

# Crear Security Groups
echo "Creando Security Groups..."
WEB_SG_ID=$(aws ec2 create-security-group \
  --group-name "web-security-group" \
  --description "Security group for web servers" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

# Configurar reglas de seguridad
aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region $REGION

aws ec2 authorize-security-group-ingress \
  --group-id $WEB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --region $REGION

# Crear instancia EC2
echo "Creando instancia EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.micro \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $WEB_SG_ID \
  --key-name my-key-pair \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server}]' \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Infraestructura desplegada exitosamente!"
echo "VPC ID: $VPC_ID"
echo "EC2 Instance ID: $INSTANCE_ID"