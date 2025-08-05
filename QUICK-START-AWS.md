# 🚀 Guía Rápida - Despliegue AWS Real

## ⚡ Despliegue en 5 Minutos

### Paso 1: Configurar AWS CLI
```bash
# Instalar AWS CLI (si no lo tienes)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
# AWS Access Key ID: [tu-access-key]
# AWS Secret Access Key: [tu-secret-key]
# Default region name: us-east-1
# Default output format: json
```

### Paso 2: Ejecutar Despliegue Automatizado
```bash
# Hacer ejecutable el script
chmod +x deploy-aws.sh

# Ejecutar despliegue
./deploy-aws.sh
```

### Paso 3: ¡Listo!
El script automáticamente:
- ✅ Crea instancia EC2 con Ubuntu
- ✅ Configura Security Group
- ✅ Crea bucket S3 público
- ✅ Sube archivos estáticos
- ✅ Crea función Lambda
- ✅ Instala Node.js y dependencias
- ✅ Configura Nginx como proxy
- ✅ Inicia la aplicación con PM2

## 🌐 Acceso a tu Demo

Después del despliegue tendrás:
- **Sitio web**: `http://TU-IP-PUBLICA`
- **API Health**: `http://TU-IP-PUBLICA/api/health`
- **Contador**: `http://TU-IP-PUBLICA/api/counter`
- **Info AWS**: `http://TU-IP-PUBLICA/api/aws-info`

## 🧹 Limpieza (Importante)

Para evitar costos:
```bash
# Hacer ejecutable
chmod +x cleanup-aws.sh

# Limpiar todos los recursos
./cleanup-aws.sh
```

## 💰 Costos Estimados

**Capa Gratuita AWS (12 meses):**
- EC2 t2.micro: 750 horas/mes GRATIS
- S3: 5GB almacenamiento GRATIS
- Lambda: 1M invocaciones GRATIS

**Después de capa gratuita:**
- EC2 t2.micro: ~$8.50/mes
- S3: ~$0.023/GB/mes
- Lambda: ~$0.20/1M invocaciones

## 🆘 Solución de Problemas

### Error: "AWS CLI not configured"
```bash
aws configure
# Ingresa tus credenciales AWS
```

### Error: "Permission denied"
```bash
chmod +x deploy-aws.sh cleanup-aws.sh
```

### Error: "Instance not accessible"
- Espera 2-3 minutos después del despliegue
- Verifica que el Security Group permite puerto 80

### Ver logs de la aplicación
```bash
# Conectar por SSH (usa la clave generada)
ssh -i aws-demo-key-XXXXX.pem ubuntu@TU-IP-PUBLICA

# Ver logs
pm2 logs aws-demo-nodejs

# Reiniciar aplicación
pm2 restart aws-demo-nodejs
```

## 📞 Soporte

Si tienes problemas:
1. Revisa `deployment-info.txt` para IDs de recursos
2. Verifica logs con SSH
3. Usa `cleanup-aws.sh` si necesitas empezar de nuevo

¡Disfruta tu demo AWS! 🎉
