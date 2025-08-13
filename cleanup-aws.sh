#!/bin/bash
# Script para limpiar recursos AWS y evitar costos

set -e

echo "🧹 Script de limpieza de recursos AWS"
echo "===================================="

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
}

# Verificar si existe archivo de información del despliegue
if [ ! -f "deployment-info.txt" ]; then
    warn "No se encontró deployment-info.txt"
    echo "Ingresa manualmente los IDs de los recursos a eliminar:"
    read -p "Instance ID (i-xxxxxxxxx): " INSTANCE_ID
    read -p "Bucket Name: " BUCKET_NAME
    read -p "Security Group ID (sg-xxxxxxxxx): " SECURITY_GROUP_ID
    read -p "Key Pair Name: " KEY_NAME
    read -p "Lambda Function Name: " LAMBDA_NAME
else
    log "Leyendo información del despliegue..."
    INSTANCE_ID=$(grep "Instancia EC2:" deployment-info.txt | cut -d' ' -f3)
    BUCKET_NAME=$(grep "Bucket S3:" deployment-info.txt | cut -d' ' -f3)
    SECURITY_GROUP_ID=$(grep "Security Group:" deployment-info.txt | cut -d' ' -f3)
    KEY_NAME=$(grep "Key Pair:" deployment-info.txt | cut -d' ' -f3 | sed 's/.pem//')
    LAMBDA_ARN=$(grep "Lambda:" deployment-info.txt | cut -d' ' -f2)
    LAMBDA_NAME=$(basename $LAMBDA_ARN)
fi

echo -e "${BLUE}Recursos a eliminar:${NC}"
echo "  📦 Instancia EC2: $INSTANCE_ID"
echo "  🗄️  Bucket S3: $BUCKET_NAME"
echo "  🛡️  Security Group: $SECURITY_GROUP_ID"
echo "  🔑 Key Pair: $KEY_NAME"
echo "  ⚡ Lambda: $LAMBDA_NAME"
echo ""

warn "⚠️  ATENCIÓN: Esta acción eliminará TODOS los recursos AWS creados."
warn "⚠️  Esta acción es IRREVERSIBLE."
echo ""
read -p "¿Estás seguro de que quieres continuar? (escribe 'DELETE' para confirmar): " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Operación cancelada."
    exit 0
fi

log "Iniciando limpieza de recursos..."

# 1. Terminar instancia EC2
if [ ! -z "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "" ]; then
    log "Terminando instancia EC2: $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID || warn "Error terminando instancia EC2"
    
    log "Esperando a que la instancia termine..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID || warn "Error esperando terminación"
    log "✅ Instancia EC2 terminada"
else
    warn "No se encontró Instance ID para eliminar"
fi

# 2. Eliminar bucket S3
if [ ! -z "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "" ]; then
    log "Eliminando bucket S3: $BUCKET_NAME"
    
    # Eliminar todos los objetos del bucket
    aws s3 rm s3://$BUCKET_NAME --recursive || warn "Error eliminando objetos de S3"
    
    # Eliminar el bucket
    aws s3 rb s3://$BUCKET_NAME || warn "Error eliminando bucket S3"
    log "✅ Bucket S3 eliminado"
else
    warn "No se encontró Bucket Name para eliminar"
fi

# 3. Eliminar función Lambda
if [ ! -z "$LAMBDA_NAME" ] && [ "$LAMBDA_NAME" != "" ]; then
    log "Eliminando función Lambda: $LAMBDA_NAME"
    aws lambda delete-function --function-name $LAMBDA_NAME || warn "Error eliminando función Lambda"
    log "✅ Función Lambda eliminada"
else
    warn "No se encontró Lambda Function para eliminar"
fi

# 4. Eliminar rol IAM de Lambda
log "Eliminando roles IAM..."
ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `lambda-execution-role`)].RoleName' --output text)
for ROLE in $ROLES; do
    if [ ! -z "$ROLE" ]; then
        log "Eliminando rol IAM: $ROLE"
        
        # Desadjuntar políticas
        POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE --query 'AttachedPolicies[].PolicyArn' --output text)
        for POLICY in $POLICIES; do
            aws iam detach-role-policy --role-name $ROLE --policy-arn $POLICY || warn "Error desadjuntando política"
        done
        
        # Eliminar rol
        aws iam delete-role --role-name $ROLE || warn "Error eliminando rol IAM"
        log "✅ Rol IAM eliminado: $ROLE"
    fi
done

# 5. Eliminar Security Group
if [ ! -z "$SECURITY_GROUP_ID" ] && [ "$SECURITY_GROUP_ID" != "" ]; then
    log "Eliminando Security Group: $SECURITY_GROUP_ID"
    
    # Esperar un poco para asegurar que la instancia esté completamente terminada
    sleep 30
    
    aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID || warn "Error eliminando Security Group"
    log "✅ Security Group eliminado"
else
    warn "No se encontró Security Group ID para eliminar"
fi

# 6. Eliminar Key Pair
if [ ! -z "$KEY_NAME" ] && [ "$KEY_NAME" != "" ]; then
    log "Eliminando Key Pair: $KEY_NAME"
    aws ec2 delete-key-pair --key-name $KEY_NAME || warn "Error eliminando Key Pair"
    
    # Eliminar archivo local de la clave
    if [ -f "${KEY_NAME}.pem" ]; then
        rm -f "${KEY_NAME}.pem"
        log "✅ Archivo de clave local eliminado"
    fi
    
    log "✅ Key Pair eliminado"
else
    warn "No se encontró Key Pair para eliminar"
fi

# 7. Limpiar archivos locales
log "Limpiando archivos locales..."
rm -f lambda-function.zip
rm -f /tmp/s3-policy.json
rm -f deploy-config.env
rm -f remote-deploy.sh

# Preguntar si eliminar deployment-info.txt
read -p "¿Eliminar archivo deployment-info.txt? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f deployment-info.txt
    log "✅ Archivo deployment-info.txt eliminado"
fi

log "🎉 Limpieza completada exitosamente!"
echo ""
echo -e "${GREEN}✅ Todos los recursos AWS han sido eliminados${NC}"
echo -e "${BLUE}💰 Ya no se generarán costos por estos recursos${NC}"
echo ""
echo -e "${YELLOW}📋 Resumen de recursos eliminados:${NC}"
echo "  📦 Instancia EC2"
echo "  🗄️  Bucket S3 y todos sus objetos"
echo "  ⚡ Función Lambda"
echo "  🔐 Roles y políticas IAM"
echo "  🛡️  Security Group"
echo "  🔑 Key Pair"
echo ""
log "Limpieza finalizada. ¡Gracias por usar AWS Demo!"
