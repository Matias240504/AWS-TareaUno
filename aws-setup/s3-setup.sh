#!/bin/bash
# Script para configurar bucket S3 y subir archivos estáticos

# Configuración
BUCKET_NAME="aws-demo-bucket-$(date +%Y%m%d%H%M%S)"
REGION="us-east-1"

echo "🗄️ Configurando Amazon S3 para AWS Demo..."
echo "📝 Bucket: $BUCKET_NAME"
echo "🌍 Región: $REGION"

# Crear bucket S3
echo "📦 Creando bucket S3..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Bucket creado exitosamente: $BUCKET_NAME"
else
    echo "❌ Error creando bucket. Verifica tus credenciales AWS."
    exit 1
fi

# Configurar bucket para hosting estático (opcional)
echo "🌐 Configurando bucket para acceso web..."
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document error.html

# Crear política de bucket para acceso público de lectura
echo "🔓 Configurando permisos públicos de lectura..."
cat > bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

# Aplicar política de bucket
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Deshabilitar bloqueo de acceso público
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Crear archivos de ejemplo si no existen
echo "📷 Creando archivos de ejemplo..."
mkdir -p ../assets

# Crear imagen placeholder para AWS logo
if [ ! -f "../assets/aws-logo.png" ]; then
    echo "🖼️ Creando placeholder para aws-logo.png..."
    # En un entorno real, aquí tendrías la imagen real
    echo "Placeholder for AWS Logo" > ../assets/aws-logo.txt
fi

# Crear más placeholders
echo "Placeholder for EC2 Diagram" > ../assets/ec2-diagram.txt
echo "Placeholder for S3 Storage" > ../assets/s3-storage.txt

# Subir archivos al bucket
echo "📤 Subiendo archivos al bucket S3..."

# Subir archivos principales del sitio web
aws s3 cp ../index.html s3://$BUCKET_NAME/ --content-type "text/html"
aws s3 cp ../styles.css s3://$BUCKET_NAME/ --content-type "text/css"
aws s3 cp ../script.js s3://$BUCKET_NAME/ --content-type "application/javascript"

# Subir archivos de assets
aws s3 cp ../assets/ s3://$BUCKET_NAME/assets/ --recursive

# Configurar metadatos y cache para archivos estáticos
echo "⚙️ Configurando metadatos de archivos..."
aws s3 cp s3://$BUCKET_NAME/styles.css s3://$BUCKET_NAME/styles.css --metadata-directive REPLACE --cache-control "max-age=31536000" --content-type "text/css"
aws s3 cp s3://$BUCKET_NAME/script.js s3://$BUCKET_NAME/script.js --metadata-directive REPLACE --cache-control "max-age=31536000" --content-type "application/javascript"

# Listar archivos subidos
echo "📋 Archivos en el bucket:"
aws s3 ls s3://$BUCKET_NAME --recursive

# Generar URLs públicas
echo "🔗 URLs públicas generadas:"
echo "   Sitio web: https://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "   Archivos directos:"
echo "   - https://$BUCKET_NAME.s3.amazonaws.com/index.html"
echo "   - https://$BUCKET_NAME.s3.amazonaws.com/styles.css"
echo "   - https://$BUCKET_NAME.s3.amazonaws.com/script.js"

# Crear archivo de configuración para usar en el sitio web
echo "📝 Creando archivo de configuración..."
cat > ../s3-config.js <<EOF
// Configuración generada automáticamente para S3
const S3_CONFIG = {
    BUCKET_NAME: '$BUCKET_NAME',
    REGION: '$REGION',
    BASE_URL: 'https://$BUCKET_NAME.s3.amazonaws.com',
    WEBSITE_URL: 'https://$BUCKET_NAME.s3-website-$REGION.amazonaws.com'
};

// Actualizar configuración en script.js
if (typeof AWS_CONFIG !== 'undefined') {
    AWS_CONFIG.S3_BUCKET_URL = S3_CONFIG.BASE_URL;
}

console.log('📦 S3 Configuration loaded:', S3_CONFIG);
EOF

# Limpiar archivos temporales
rm -f bucket-policy.json

echo "✅ Configuración de S3 completada!"
echo "📋 Información del bucket:"
echo "   Nombre: $BUCKET_NAME"
echo "   Región: $REGION"
echo "   URL base: https://$BUCKET_NAME.s3.amazonaws.com"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Incluir s3-config.js en tu HTML"
echo "   2. Actualizar script.js con las URLs reales"
echo "   3. Probar acceso a los archivos desde el navegador"
echo ""
echo "💡 Comandos útiles:"
echo "   - Sincronizar cambios: aws s3 sync ../ s3://$BUCKET_NAME --exclude '*.sh' --exclude 'aws-setup/*'"
echo "   - Ver logs: aws s3api get-bucket-logging --bucket $BUCKET_NAME"
echo "   - Eliminar bucket: aws s3 rb s3://$BUCKET_NAME --force"
