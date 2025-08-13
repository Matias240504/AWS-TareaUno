# 🚀 AWS Demo - Tarea de Servicios Básicos

Este proyecto demuestra el uso de servicios fundamentales de Amazon Web Services (AWS) para crear una aplicación web básica.

## 📋 Objetivos del Proyecto

- **EC2**: Configurar una instancia Ubuntu Server y desplegar un sitio web básico
- **S3**: Almacenar archivos estáticos (imágenes, recursos) y vincularlos desde la web
- **IAM**: Configurar roles y permisos de acceso entre servicios
- **Lambda** (Bonus): Implementar una función serverless para contador de visitas

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Usuario Web   │───▶│   EC2 Instance  │───▶│   S3 Bucket     │
│                 │    │   (Ubuntu)      │    │   (Archivos)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Lambda Function│───▶│   IAM Roles     │
                       │  (Contador)     │    │   (Permisos)    │
                       └─────────────────┘    └─────────────────┘
```

## 📁 Estructura del Proyecto

```
tarea1/
├── index.html          # Página principal del sitio web
├── styles.css          # Estilos CSS del sitio
├── script.js           # JavaScript para interacciones
├── README.md           # Este archivo
├── aws-setup/          # Scripts y configuraciones AWS
│   ├── ec2-setup.sh    # Script para configurar EC2
│   ├── s3-setup.sh     # Script para configurar S3
│   ├── iam-policy.json # Políticas IAM
│   └── lambda-function.py # Función Lambda
└── assets/             # Archivos para subir a S3
    ├── aws-logo.png
    ├── ec2-diagram.jpg
    └── s3-storage.png
```

## 🛠️ Servicios AWS Utilizados

### 1. Amazon EC2 (Elastic Compute Cloud)
- **Propósito**: Servidor web para alojar el sitio HTML
- **Configuración**: Instancia t2.micro con Ubuntu Server
- **Puerto**: 80 (HTTP) y 22 (SSH)

### 2. Amazon S3 (Simple Storage Service)
- **Propósito**: Almacenar imágenes y archivos estáticos
- **Configuración**: Bucket público con políticas de lectura
- **Integración**: URLs de S3 vinculadas desde el sitio web

### 3. AWS IAM (Identity and Access Management)
- **Propósito**: Gestionar permisos entre servicios
- **Roles**: EC2 → S3, Lambda → CloudWatch
- **Políticas**: Acceso mínimo necesario (principio de menor privilegio)

### 4. AWS Lambda (Serverless)
- **Propósito**: Función para contar visitas a la página
- **Trigger**: API Gateway o llamada directa desde JavaScript
- **Runtime**: Python 3.9

## 🚀 Pasos de Implementación

### Fase 1: Configuración EC2
1. Crear instancia EC2 Ubuntu Server t2.micro
2. Configurar Security Groups (puertos 80, 22)
3. Conectar vía SSH y configurar servidor web
4. Subir archivos del sitio web

### Fase 2: Configuración S3
1. Crear bucket S3 con nombre único
2. Subir imágenes y archivos estáticos
3. Configurar permisos públicos de lectura
4. Actualizar URLs en el sitio web

### Fase 3: Configuración IAM
1. Crear rol para EC2 con acceso a S3
2. Crear rol para Lambda con acceso a CloudWatch
3. Aplicar políticas de seguridad

### Fase 4: Función Lambda (Bonus)
1. Crear función Lambda para contador
2. Configurar API Gateway (opcional)
3. Integrar con el sitio web

## 📝 Comandos Útiles

### Conectar a EC2
```bash
ssh -i "tu-key.pem" ubuntu@tu-ec2-ip
```

### Configurar servidor web en EC2
```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Subir archivos a S3
```bash
aws s3 cp index.html s3://tu-bucket-name/
aws s3 cp styles.css s3://tu-bucket-name/
aws s3 cp script.js s3://tu-bucket-name/
```

## 🔧 Configuración Local para Desarrollo

1. Abrir `index.html` en un navegador para probar localmente
2. Modificar `AWS_CONFIG` en `script.js` con tus URLs reales
3. Probar funcionalidades antes de desplegar

## 📊 Monitoreo y Logs

- **EC2**: Logs del servidor web en `/var/log/nginx/`
- **S3**: Métricas de acceso en CloudWatch
- **Lambda**: Logs en CloudWatch Logs
- **Costos**: Monitorear en AWS Cost Explorer

## 🎯 Resultados Esperados

Al completar este proyecto, tendrás:
- ✅ Un sitio web funcionando en EC2
- ✅ Imágenes servidas desde S3
- ✅ Roles IAM configurados correctamente
- ✅ Función Lambda operativa (bonus)
- ✅ Conocimiento práctico de servicios AWS básicos

## 💡 Próximos Pasos (Opcional)

- Configurar HTTPS con Certificate Manager
- Implementar CloudFront para CDN
- Agregar base de datos RDS
- Configurar Auto Scaling
- Implementar CI/CD con CodePipeline

## 📞 Soporte

Para dudas sobre AWS:
- [Documentación oficial de AWS](https://docs.aws.amazon.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Training](https://aws.amazon.com/training/)

---
**Nota**: Este proyecto está diseñado para usar servicios dentro del AWS Free Tier para minimizar costos.
