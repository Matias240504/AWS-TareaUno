const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');
const AWS = require('aws-sdk');
require('dotenv').config();

// Configurar AWS SDK
AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// Inicializar servicios AWS
const ec2 = new AWS.EC2();
const s3 = new AWS.S3();
const lambda = new AWS.Lambda();

// Variables de configuración AWS
const s3Region = process.env.S3_REGION || process.env.AWS_REGION || 'us-east-1';
const ec2InstanceId = process.env.EC2_INSTANCE_ID;
const lambdaFunctionName = process.env.LAMBDA_FUNCTION_NAME || 'visit-counter';

// Función auxiliar para formatear bytes
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Crear aplicación Express
const app = express();

// Configuración del servidor - buscar puerto disponible
const net = require('net');
let PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

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
      styleSrc: ["'self'", "'unsafe-inline'", "http:", "https:"],
      scriptSrc: ["'self'", "'unsafe-inline'", "http:", "https:"],
      scriptSrcAttr: ["'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "http:", "https:", "*.amazonaws.com"],
      connectSrc: ["'self'", "http:", "https:"],
      fontSrc: ["'self'", "http:", "https:", "data:"],
    },
  },
  crossOriginEmbedderPolicy: false,
}));

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(morgan('combined'));
// Aumentar límite para subida de archivos (50MB)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Servir archivos estáticos con configuración mejorada
app.use(express.static(path.join(__dirname, 'public'), {
  setHeaders: (res, path) => {
    if (path.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css');
    }
    if (path.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript');
    }
  }
}));

// Variables globales para simular datos
let visitCounter = parseInt(process.env.VISIT_COUNTER || '100');
const s3BucketName = process.env.S3_BUCKET_NAME || 'aws-demo-1754583296-usuario';
const awsRegion = process.env.AWS_REGION || 'us-east-1';

// Ruta principal - servir index.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API para obtener información real de AWS
app.get('/api/aws-info', async (req, res) => {
  try {
    console.log('🔍 Getting real AWS info...');
    
    // Obtener información de EC2
    let ec2Info = {
      instanceId: process.env.EC2_INSTANCE_ID || 'No configurado',
      instanceType: 't2.micro',
      region: awsRegion,
      status: 'unknown',
      publicIp: 'No disponible'
    };
    
    if (process.env.EC2_INSTANCE_ID) {
      try {
        const ec2Data = await ec2.describeInstances({
          InstanceIds: [process.env.EC2_INSTANCE_ID]
        }).promise();
        
        const instance = ec2Data.Reservations[0]?.Instances[0];
        if (instance) {
          ec2Info.status = instance.State.Name;
          ec2Info.publicIp = instance.PublicIpAddress || 'No asignada';
          ec2Info.instanceType = instance.InstanceType;
        }
      } catch (ec2Error) {
        console.warn('⚠️ Error getting EC2 info:', ec2Error.message);
      }
    }
    
    // Obtener información de S3
    let s3Info = {
      bucketName: s3BucketName,
      region: awsRegion,
      objects: 0,
      size: '0 B',
      url: `https://${s3BucketName}.s3.amazonaws.com`,
      exists: false
    };
    
    try {
      await s3.headBucket({ Bucket: s3BucketName }).promise();
      s3Info.exists = true;
      
      const objects = await s3.listObjectsV2({ Bucket: s3BucketName }).promise();
      s3Info.objects = objects.KeyCount || 0;
      
      const totalSize = objects.Contents?.reduce((sum, obj) => sum + obj.Size, 0) || 0;
      s3Info.size = formatBytes(totalSize);
    } catch (s3Error) {
      console.warn('⚠️ S3 bucket not accessible:', s3Error.message);
    }
    
    const awsInfo = {
      ec2: ec2Info,
      s3: s3Info,
      lambda: {
        functionName: process.env.LAMBDA_FUNCTION_NAME || 'aws-demo-counter',
        runtime: 'python3.9',
        status: 'checking...'
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
  } catch (error) {
    console.error('❌ Error getting AWS info:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting AWS information',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
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

// API para listar archivos S3 (real)
app.get('/api/s3/files', async (req, res) => {
  try {
    console.log('📁 Getting real S3 files list from bucket:', s3BucketName);
    
    // Verificar si el bucket existe
    try {
      await s3.headBucket({ Bucket: s3BucketName }).promise();
    } catch (bucketError) {
      console.log('❌ Error checking S3 bucket:', bucketError);
      return res.status(404).json({
        success: false,
        message: `S3 bucket '${s3BucketName}' not found or not accessible`,
        error: bucketError,
        timestamp: new Date().toISOString()
      });
    }
    
    // Listar objetos del bucket
    const listParams = {
      Bucket: s3BucketName,
      MaxKeys: 100
    };
    
    const data = await s3.listObjectsV2(listParams).promise();
    
    const s3Files = data.Contents?.map(obj => ({
      key: obj.Key,
      size: obj.Size,
      lastModified: obj.LastModified.toISOString(),
      url: `https://${s3BucketName}.s3.amazonaws.com/${obj.Key}`,
      etag: obj.ETag,
      storageClass: obj.StorageClass || 'STANDARD'
    })) || [];

    res.json({
      success: true,
      bucket: s3BucketName,
      files: s3Files,
      count: s3Files.length,
      totalSize: formatBytes(s3Files.reduce((sum, file) => sum + file.size, 0)),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error listing S3 files:', error);
    res.status(500).json({
      success: false,
      message: 'Error listing S3 files',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// API para subir archivo a S3 (real)
app.post('/api/s3/upload', async (req, res) => {
  try {
    console.log('📤 Uploading file to S3...');
    
    const fileName = req.body.fileName || `upload-${Date.now()}.txt`;
    const fileContent = req.body.fileContent;
    const contentType = req.body.contentType || 'application/octet-stream';
    
    if (!fileContent) {
      return res.status(400).json({
        success: false,
        message: 'File content is required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Convertir base64 a buffer si es necesario
    let fileBuffer;
    try {
      // Si el contenido viene en base64, convertirlo a buffer
      if (typeof fileContent === 'string' && fileContent.length > 0) {
        fileBuffer = Buffer.from(fileContent, 'base64');
      } else {
        fileBuffer = fileContent;
      }
    } catch (bufferError) {
      console.error('❌ Error converting file content:', bufferError);
      return res.status(400).json({
        success: false,
        message: 'Invalid file content format',
        error: bufferError.message,
        timestamp: new Date().toISOString()
      });
    }
    
    // Parámetros para la subida
    const uploadParams = {
      Bucket: s3BucketName,
      Key: `uploads/${fileName}`,
      Body: fileBuffer,
      ContentType: contentType,
      // ACL removido - el bucket usa políticas para acceso público
      Metadata: {
        'uploaded-by': 'aws-demo-app',
        'upload-timestamp': new Date().toISOString()
      }
    };
    
    console.log(`📤 Uploading ${fileName} (${formatBytes(fileBuffer.length)}) to S3...`);
    
    // Subir archivo a S3
    const uploadResult = await s3.upload(uploadParams).promise();
    
    console.log('✅ File uploaded successfully:', uploadResult.Location);
    
    res.json({
      success: true,
      message: 'File uploaded successfully to S3',
      file: {
        key: uploadResult.Key,
        url: uploadResult.Location,
        bucket: uploadResult.Bucket,
        etag: uploadResult.ETag,
        size: fileBuffer.length,
        contentType: contentType,
        uploadedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('❌ Error uploading to S3:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading file to S3',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
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

// Endpoint para debug de archivos estáticos
app.get('/api/debug/files', (req, res) => {
  const publicPath = path.join(__dirname, 'public');
  
  try {
    const files = fs.readdirSync(publicPath);
    const fileDetails = files.map(file => {
      const filePath = path.join(publicPath, file);
      const stats = fs.statSync(filePath);
      return {
        name: file,
        size: stats.size,
        isFile: stats.isFile(),
        path: `/public/${file}`
      };
    });
    
    res.json({
      success: true,
      publicPath: publicPath,
      files: fileDetails,
      cssExists: fs.existsSync(path.join(publicPath, 'styles.css')),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      publicPath: publicPath
    });
  }
});

//ENDPOINT PARA AUTOMATIZACION DE DEPLOYMENT
/* Webhook para auto-deployment (opcional)
app.post('/api/webhook/deploy', (req, res) => {
  // Verificar que sea un push al branch main
  if (req.body.ref === 'refs/heads/main') {
    console.log('🔄 Webhook received: Updating application...');
    
    const { exec } = require('child_process');
    
    // Ejecutar script de actualización
    exec('/home/ubuntu/update-app.sh', (error, stdout, stderr) => {
      if (error) {
        console.error('❌ Deployment error:', error);
        return res.status(500).json({
          success: false,
          message: 'Deployment failed',
          error: error.message
        });
      }
      
      console.log('✅ Deployment successful:', stdout);
      res.json({
        success: true,
        message: 'Application updated successfully',
        output: stdout
      });
    });
  } else {
    res.json({
      success: false,
      message: 'Not a main branch push, ignoring'
    });
  }
});*/

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
        
        app.listen(PORT, HOST, () => {
            console.log(`🚀 Servidor AWS Demo iniciado en http://${HOST}:${PORT}`);
            console.log(`📊 Health check: http://${HOST}:${PORT}/api/health`);
            console.log(`☁️ AWS Info: http://${HOST}:${PORT}/api/aws-info`);
            console.log(`📈 Counter: http://${HOST}:${PORT}/api/counter`);
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
