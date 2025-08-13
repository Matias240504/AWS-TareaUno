#!/bin/bash
# Script para configurar instancia EC2 Ubuntu Server

echo "🚀 Configurando instancia EC2 para AWS Demo..."

# Actualizar sistema
echo "📦 Actualizando paquetes del sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Nginx
echo "🌐 Instalando servidor web Nginx..."
sudo apt install nginx -y

# Iniciar y habilitar Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Crear directorio para el sitio web
echo "📁 Configurando directorio del sitio web..."
sudo mkdir -p /var/www/aws-demo
sudo chown -R $USER:$USER /var/www/aws-demo
sudo chmod -R 755 /var/www/aws-demo

# Configurar Nginx para servir nuestro sitio
echo "⚙️ Configurando Nginx..."
sudo tee /etc/nginx/sites-available/aws-demo > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root /var/www/aws-demo;
    index index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Configurar headers para archivos estáticos
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar el sitio
sudo ln -sf /etc/nginx/sites-available/aws-demo /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
sudo nginx -t

# Reiniciar Nginx
sudo systemctl reload nginx

# Instalar AWS CLI
echo "☁️ Instalando AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configurar firewall básico
echo "🔒 Configurando firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw --force enable

# Crear script para desplegar sitio web
echo "📝 Creando script de despliegue..."
tee ~/deploy-site.sh > /dev/null <<EOF
#!/bin/bash
# Script para desplegar el sitio web

echo "📤 Desplegando sitio web AWS Demo..."

# Copiar archivos al directorio web
cp ~/index.html /var/www/aws-demo/
cp ~/styles.css /var/www/aws-demo/
cp ~/script.js /var/www/aws-demo/

# Ajustar permisos
sudo chown -R www-data:www-data /var/www/aws-demo
sudo chmod -R 644 /var/www/aws-demo/*

echo "✅ Sitio web desplegado exitosamente!"
echo "🌐 Visita: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
EOF

chmod +x ~/deploy-site.sh

# Mostrar información del sistema
echo "📊 Información del sistema:"
echo "- OS: $(lsb_release -d | cut -f2)"
echo "- Nginx: $(nginx -v 2>&1)"
echo "- AWS CLI: $(aws --version)"
echo "- IP Pública: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

echo "✅ Configuración de EC2 completada!"
echo "📋 Próximos pasos:"
echo "   1. Subir archivos del sitio web (index.html, styles.css, script.js)"
echo "   2. Ejecutar: ~/deploy-site.sh"
echo "   3. Configurar S3 y actualizar URLs en script.js"
