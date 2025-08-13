#!/bin/bash
# Script para configurar credenciales AWS

echo "🔑 Configuración de Credenciales AWS"
echo "=================================="

# Verificar si AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado."
    echo "📥 Descárgalo desde: https://aws.amazon.com/cli/"
    echo ""
    echo "En Linux/WSL ejecuta:"
    echo "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
    echo "unzip awscliv2.zip"
    echo "sudo ./aws/install"
    exit 1
fi

echo "✅ AWS CLI encontrado: $(aws --version)"
echo ""

echo "📋 Necesitas las siguientes credenciales de tu cuenta AWS:"
echo "   1. Access Key ID (empieza con AKIA...)"
echo "   2. Secret Access Key (cadena larga alfanumérica)"
echo ""
echo "🔗 Para obtenerlas:"
echo "   1. Ve a AWS Console → IAM → Users"
echo "   2. Crea usuario 'aws-demo-user' con acceso programático"
echo "   3. Asigna permisos: EC2FullAccess, S3FullAccess, IAMFullAccess, LambdaFullAccess"
echo "   4. Descarga las credenciales"
echo ""

read -p "¿Ya tienes las credenciales? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Ve a AWS Console primero y obtén las credenciales."
    echo "Luego ejecuta este script nuevamente."
    exit 0
fi

echo "🔧 Configurando AWS CLI..."
echo ""
echo "Ingresa tus credenciales AWS:"

# Configurar AWS CLI interactivamente
aws configure

echo ""
echo "🧪 Probando conexión..."

# Verificar configuración
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ ¡Credenciales configuradas correctamente!"
    
    # Mostrar información de la cuenta
    echo ""
    echo "📊 Información de tu cuenta AWS:"
    aws sts get-caller-identity
    
    echo ""
    echo "🚀 ¡Listo para desplegar!"
    echo "Ejecuta: ./deploy-aws.sh"
    
else
    echo "❌ Error en la configuración de credenciales."
    echo "Verifica que:"
    echo "   - Las credenciales sean correctas"
    echo "   - El usuario tenga los permisos necesarios"
    echo "   - Tu conexión a internet funcione"
fi
