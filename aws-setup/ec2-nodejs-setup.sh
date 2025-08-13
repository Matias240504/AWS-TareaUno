#!/bin/bash
# Script para configurar instancia EC2 Ubuntu Server con Node.js

echo "🚀 Configurando instancia EC2 para AWS Demo Node.js..."

# Actualizar sistema
echo "📦 Actualizando paquetes del sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Node.js y npm
echo "📗 Instalando Node.js y npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalación
echo "✅ Verificando instalación de Node.js..."
node --version
npm --version

# Instalar PM2 para gestión de procesos
echo "⚙️ Instalando PM2..."
sudo npm install -g pm2

# Instalar Nginx como proxy reverso
echo "🌐 Instalando Nginx..."
sudo apt install nginx -y

# Configurar Nginx como proxy reverso para Node.js
echo "⚙️ Configurando Nginx como proxy reverso..."
sudo tee /etc/nginx/sites-available/aws-demo-nodejs > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Servir archivos estáticos directamente (opcional)
    location /static/ {
        alias /home/ubuntu/aws-demo-nodejs/public/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Habilitar el sitio
sudo ln -sf /etc/nginx/sites-available/aws-demo-nodejs /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración de Nginx
sudo nginx -t

# Reiniciar servicios
sudo systemctl restart nginx
sudo systemctl enable nginx

# Instalar AWS CLI
echo "☁️ Instalando AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configurar firewall
echo "🔒 Configurando firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw allow 3000/tcp
sudo ufw --force enable

# Crear directorio para la aplicación
echo "📁 Creando directorio de aplicación..."
mkdir -p ~/aws-demo-nodejs
cd ~/aws-demo-nodejs

# Crear script de despliegue
echo "📝 Creando script de despliegue..."
tee ~/deploy-nodejs-app.sh > /dev/null <<EOF
#!/bin/bash
# Script para desplegar aplicación Node.js

echo "📤 Desplegando aplicación AWS Demo Node.js..."

# Ir al directorio de la aplicación
cd ~/aws-demo-nodejs

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    echo "⚙️ Creando archivo de configuración..."
    cp .env.example .env
    
    # Obtener IP pública de la instancia
    PUBLIC_IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    INSTANCE_ID=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    
    # Actualizar variables de entorno
    sed -i "s/EC2_PUBLIC_IP=/EC2_PUBLIC_IP=\$PUBLIC_IP/" .env
    sed -i "s/EC2_INSTANCE_ID=i-1234567890abcdef0/EC2_INSTANCE_ID=\$INSTANCE_ID/" .env
    
    echo "✅ Archivo .env configurado con IP: \$PUBLIC_IP"
fi

# Detener aplicación si está ejecutándose
echo "🛑 Deteniendo aplicación anterior..."
pm2 stop aws-demo-nodejs 2>/dev/null || true
pm2 delete aws-demo-nodejs 2>/dev/null || true

# Iniciar aplicación con PM2
echo "🚀 Iniciando aplicación..."
pm2 start server.js --name "aws-demo-nodejs"

# Configurar PM2 para inicio automático
pm2 startup
pm2 save

# Verificar estado
pm2 status

echo "✅ Aplicación desplegada exitosamente!"
echo "🌐 Visita: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "📊 Logs: pm2 logs aws-demo-nodejs"
echo "🔄 Reiniciar: pm2 restart aws-demo-nodejs"
EOF

chmod +x ~/deploy-nodejs-app.sh

# Crear script de monitoreo
tee ~/monitor-app.sh > /dev/null <<EOF
#!/bin/bash
# Script para monitorear la aplicación

echo "📊 Estado de la aplicación AWS Demo Node.js"
echo "=========================================="

# Estado de PM2
echo "🔄 Procesos PM2:"
pm2 status

echo ""
echo "📈 Uso de recursos:"
pm2 monit --no-daemon | head -20

echo ""
echo "📋 Últimos logs:"
pm2 logs aws-demo-nodejs --lines 10 --nostream

echo ""
echo "🌐 Estado de Nginx:"
sudo systemctl status nginx --no-pager -l

echo ""
echo "🔗 URLs de la aplicación:"
PUBLIC_IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "   - Aplicación: http://\$PUBLIC_IP"
echo "   - API Health: http://\$PUBLIC_IP/api/health"
echo "   - AWS Info: http://\$PUBLIC_IP/api/aws-info"
EOF

chmod +x ~/monitor-app.sh

# Mostrar información del sistema
echo "📊 Información del sistema:"
echo "- OS: $(lsb_release -d | cut -f2)"
echo "- Node.js: $(node --version)"
echo "- npm: $(npm --version)"
echo "- PM2: $(pm2 --version)"
echo "- Nginx: $(nginx -v 2>&1)"
echo "- AWS CLI: $(aws --version)"
echo "- IP Pública: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

echo "✅ Configuración de EC2 para Node.js completada!"
echo "📋 Próximos pasos:"
echo "   1. Subir archivos de la aplicación Node.js"
echo "   2. Ejecutar: ~/deploy-nodejs-app.sh"
echo "   3. Configurar S3 y actualizar variables de entorno"
echo "   4. Monitorear con: ~/monitor-app.sh"
echo ""
echo "💡 Comandos útiles:"
echo "   - Ver logs: pm2 logs aws-demo-nodejs"
echo "   - Reiniciar app: pm2 restart aws-demo-nodejs"
echo "   - Estado Nginx: sudo systemctl status nginx"
echo "   - Recargar Nginx: sudo systemctl reload nginx"
