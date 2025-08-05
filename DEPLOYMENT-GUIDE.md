# 🚀 Guía de Despliegue AWS

Esta guía te llevará paso a paso para desplegar la demo de AWS en la nube.

## 📋 Prerrequisitos

1. **Cuenta de AWS** con acceso a Free Tier
2. **AWS CLI** instalado y configurado
3. **Par de llaves SSH** para EC2
4. **Permisos IAM** para crear recursos

## 🔧 Configuración Inicial

### 1. Configurar AWS CLI
```bash
aws configure
# Ingresa tu Access Key ID
# Ingresa tu Secret Access Key  
# Región: us-east-1
# Formato: json
```

### 2. Verificar Configuración
```bash
aws sts get-caller-identity
```

## 🖥️ Paso 1: Configurar EC2

### Crear Instancia EC2
1. Ve a la consola de EC2
2. Lanza nueva instancia:
   - **AMI**: Ubuntu Server 22.04 LTS
   - **Tipo**: t2.micro (Free Tier)
   - **Key Pair**: Crea o selecciona uno existente
   - **Security Group**: Permitir HTTP (80) y SSH (22)

### Conectar y Configurar
```bash
# Conectar a la instancia
ssh -i "tu-key.pem" ubuntu@tu-ip-publica

# Subir script de configuración
scp -i "tu-key.pem" aws-setup/ec2-setup.sh ubuntu@tu-ip-publica:~/

# Ejecutar configuración
chmod +x ec2-setup.sh
./ec2-setup.sh
```

### Subir Archivos del Sitio
```bash
# Desde tu máquina local
scp -i "tu-key.pem" index.html ubuntu@tu-ip-publica:~/
scp -i "tu-key.pem" styles.css ubuntu@tu-ip-publica:~/
scp -i "tu-key.pem" script.js ubuntu@tu-ip-publica:~/

# En la instancia EC2
./deploy-site.sh
```

## 🗄️ Paso 2: Configurar S3

### Ejecutar Script de S3
```bash
# En tu máquina local o en EC2
chmod +x aws-setup/s3-setup.sh
./aws-setup/s3-setup.sh
```

### Verificar Bucket
```bash
# Listar buckets
aws s3 ls

# Verificar archivos subidos
aws s3 ls s3://tu-bucket-name --recursive
```

### Probar Acceso Público
Visita en tu navegador:
- `https://tu-bucket-name.s3.amazonaws.com/index.html`

## 🔐 Paso 3: Configurar IAM

### Crear Rol para EC2
```bash
# Crear rol
aws iam create-role --role-name EC2-S3-Access --assume-role-policy-document file://trust-policy.json

# Adjuntar política
aws iam attach-role-policy --role-name EC2-S3-Access --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Crear instance profile
aws iam create-instance-profile --instance-profile-name EC2-S3-Profile
aws iam add-role-to-instance-profile --instance-profile-name EC2-S3-Profile --role-name EC2-S3-Access
```

### Asignar Rol a EC2
1. Ve a la consola de EC2
2. Selecciona tu instancia
3. Actions → Security → Modify IAM role
4. Selecciona `EC2-S3-Profile`

## ⚡ Paso 4: Configurar Lambda (Bonus)

### Crear Función Lambda
```bash
# Comprimir función
zip lambda-function.zip lambda-function.py

# Crear función
aws lambda create-function \
    --function-name aws-demo-counter \
    --runtime python3.9 \
    --role arn:aws:iam::TU-ACCOUNT-ID:role/lambda-execution-role \
    --handler lambda-function.lambda_handler \
    --zip-file fileb://lambda-function.zip
```

### Configurar API Gateway (Opcional)
1. Ve a la consola de API Gateway
2. Crea nueva REST API
3. Crea recurso `/counter`
4. Crea método POST
5. Integra con función Lambda
6. Habilita CORS
7. Despliega API

### Actualizar JavaScript
Edita `script.js` y actualiza:
```javascript
const AWS_CONFIG = {
    LAMBDA_COUNTER_URL: 'https://tu-api-gateway-url/counter',
    S3_BUCKET_URL: 'https://tu-bucket-name.s3.amazonaws.com'
};
```

## 🧪 Paso 5: Probar Todo

### Verificar EC2
- Visita: `http://tu-ip-publica-ec2`
- Debe mostrar el sitio web

### Verificar S3
- Las imágenes deben cargar desde S3
- Verifica en Developer Tools → Network

### Verificar Lambda
- El contador debe funcionar
- Verifica logs en CloudWatch

## 📊 Monitoreo

### CloudWatch
- Ve a CloudWatch para ver métricas
- Configura alarmas si es necesario

### Costos
- Monitorea en AWS Cost Explorer
- Todo debe estar en Free Tier

## 🔧 Solución de Problemas

### EC2 no accesible
- Verifica Security Groups
- Confirma que Nginx esté ejecutándose: `sudo systemctl status nginx`

### S3 archivos no accesibles
- Verifica permisos del bucket
- Confirma política pública

### Lambda no responde
- Verifica logs en CloudWatch
- Confirma permisos del rol

## 🧹 Limpieza (Opcional)

Para evitar costos, elimina recursos:
```bash
# Eliminar bucket S3
aws s3 rb s3://tu-bucket-name --force

# Terminar instancia EC2 (desde consola)

# Eliminar función Lambda
aws lambda delete-function --function-name aws-demo-counter
```

## ✅ Lista de Verificación

- [ ] Instancia EC2 ejecutándose
- [ ] Sitio web accesible vía HTTP
- [ ] Bucket S3 creado y configurado
- [ ] Archivos subidos a S3
- [ ] Roles IAM configurados
- [ ] Función Lambda desplegada (bonus)
- [ ] Todo funcionando en conjunto

## 📞 Soporte

Si tienes problemas:
1. Verifica logs de cada servicio
2. Confirma permisos IAM
3. Revisa Security Groups
4. Consulta documentación AWS
