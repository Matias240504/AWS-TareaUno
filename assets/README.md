# 📁 Assets - Archivos para S3

Esta carpeta contiene los archivos estáticos que se subirán al bucket de Amazon S3.

## 📋 Archivos Incluidos

- **aws-logo.png**: Logo de AWS para mostrar en la galería
- **ec2-diagram.jpg**: Diagrama explicativo de EC2
- **s3-storage.png**: Imagen representativa de S3

## 📤 Subir a S3

Estos archivos se subirán automáticamente al bucket S3 usando el script:
```bash
./aws-setup/s3-setup.sh
```

## 🔗 URLs de Acceso

Una vez subidos a S3, los archivos estarán disponibles en:
```
https://tu-bucket-name.s3.amazonaws.com/assets/aws-logo.png
https://tu-bucket-name.s3.amazonaws.com/assets/ec2-diagram.jpg
https://tu-bucket-name.s3.amazonaws.com/assets/s3-storage.png
```

## 📝 Notas

- Los archivos actuales son placeholders de texto
- En un proyecto real, aquí irían las imágenes reales
- Los permisos se configuran automáticamente para acceso público de lectura
