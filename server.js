const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Crear aplicación Express
const app = express();

// Configuración del servidor - buscar puerto disponible
const net = require('net');
let PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || 'localhost';

// Función para verificar si un puerto está disponible
function isPortAvailable(port) {
    return new Promise((resolve) => {
        const server = net.createServer();
        server.listen(port, (err) => {
            if (err) {
                server.close();
                resolve(false);
            } else {
                server.close();
                resolve(true);
            }
        });
        server.on('error', () => resolve(false));
    });
}

// Función para encontrar puerto disponible
async function findAvailablePort(startPort) {
    for (let port = startPort; port <= startPort + 100; port++) {
        if (await isPortAvailable(port)) {
            return port;
        }
    }
    throw new Error('No se pudo encontrar un puerto disponible');
}

// Configuración de middlewares
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:", "*.amazonaws.com"],
    },
  },
}));

app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir archivos estáticos
app.use(express.static(path.join(__dirname, 'public')));

// Variables globales para simular datos
let visitCounter = parseInt(process.env.VISIT_COUNTER || '100');
const s3BucketName = process.env.S3_BUCKET_NAME || 'aws-demo-bucket-placeholder';
const awsRegion = process.env.AWS_REGION || 'us-east-1';

// Ruta principal - servir index.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API para obtener información de AWS
app.get('/api/aws-info', (req, res) => {
  const awsInfo = {
    ec2: {
      instanceId: process.env.EC2_INSTANCE_ID || 'i-1234567890abcdef0',
      instanceType: 't2.micro',
      region: awsRegion,
      status: 'running',
      publicIp: process.env.EC2_PUBLIC_IP || 'Obteniendo...'
    },
    s3: {
      bucketName: s3BucketName,
      region: awsRegion,
      objects: 3,
      size: '2.5 MB',
      url: `https://${s3BucketName}.s3.amazonaws.com`
    },
    lambda: {
      functionName: 'aws-demo-counter',
      runtime: 'python3.9',
      status: 'active'
    },
    iam: {
      roles: ['EC2-S3-Access', 'Lambda-Execution-Role'],
      policies: ['S3ReadOnlyAccess', 'CloudWatchLogsFullAccess']
    }
  };

  res.json({
    success: true,
    data: awsInfo,
    timestamp: new Date().toISOString()
  });
});

// API para contador de visitas (simula Lambda)
app.get('/api/counter', (req, res) => {
  console.log('📊 Getting visit counter');
  
  res.json({
    success: true,
    count: visitCounter,
    message: 'Counter retrieved successfully',
    timestamp: new Date().toISOString()
  });
});

app.post('/api/counter/increment', (req, res) => {
  console.log('🔄 Incrementing visit counter');
  
  visitCounter++;
  
  res.json({
    success: true,
    count: visitCounter,
    message: 'Counter incremented successfully',
    timestamp: new Date().toISOString()
  });
});

app.post('/api/counter/reset', (req, res) => {
  console.log('🔄 Resetting visit counter');
  
  visitCounter = 0;
  
  res.json({
    success: true,
    count: visitCounter,
    message: 'Counter reset successfully',
    timestamp: new Date().toISOString()
  });
});

// API para listar archivos S3 (simulado)
app.get('/api/s3/files', (req, res) => {
  console.log('📁 Getting S3 files list');
  
  const s3Files = [
    {
      key: 'assets/aws-logo.png',
      size: 1024,
      lastModified: new Date().toISOString(),
      url: `https://${s3BucketName}.s3.amazonaws.com/assets/aws-logo.png`
    },
    {
      key: 'assets/ec2-diagram.jpg',
      size: 2048,
      lastModified: new Date().toISOString(),
      url: `https://${s3BucketName}.s3.amazonaws.com/assets/ec2-diagram.jpg`
    },
    {
      key: 'assets/s3-storage.png',
      size: 1536,
      lastModified: new Date().toISOString(),
      url: `https://${s3BucketName}.s3.amazonaws.com/assets/s3-storage.png`
    }
  ];

  res.json({
    success: true,
    bucket: s3BucketName,
    files: s3Files,
    count: s3Files.length,
    timestamp: new Date().toISOString()
  });
});

// API para subir archivo a S3 (simulado)
app.post('/api/s3/upload', (req, res) => {
  console.log('📤 Simulating S3 upload');
  
  // En producción, aquí usarías AWS SDK para subir realmente a S3
  const fileName = req.body.fileName || 'uploaded-file.txt';
  const fileSize = req.body.fileSize || 1024;
  
  res.json({
    success: true,
    message: 'File uploaded successfully (simulated)',
    file: {
      key: `uploads/${fileName}`,
      size: fileSize,
      url: `https://${s3BucketName}.s3.amazonaws.com/uploads/${fileName}`,
      uploadedAt: new Date().toISOString()
    }
  });
});

// API de salud del servidor
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'AWS Demo Node.js Server is running',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Middleware para rutas no encontradas
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err);
  
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    timestamp: new Date().toISOString()
  });
});

// Iniciar servidor con puerto disponible
async function startServer() {
    try {
        PORT = await findAvailablePort(PORT);
        
        app.listen(PORT, () => {
            console.log(`🚀 Servidor AWS Demo iniciado en http://localhost:${PORT}`);
            console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
            console.log(`☁️ AWS Info: http://localhost:${PORT}/api/aws-info`);
            console.log(`📈 Counter: http://localhost:${PORT}/api/counter`);
            console.log('✅ Servidor listo para recibir conexiones');
        });
    } catch (error) {
        console.error('❌ Error iniciando servidor:', error.message);
        process.exit(1);
    }
}

// Iniciar el servidor
startServer();

// Manejo de cierre graceful
process.on('SIGTERM', () => {
  console.log('\n🛑 SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\n🛑 SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

module.exports = app;
