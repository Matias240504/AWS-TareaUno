// AWS Demo Site - JavaScript para Node.js Backend

// Configuración de la aplicación
const APP_CONFIG = {
    // Base URL de la API (se ajusta automáticamente)
    API_BASE_URL: window.location.origin,
    
    // Endpoints de la API
    ENDPOINTS: {
        HEALTH: '/api/health',
        AWS_INFO: '/api/aws-info',
        COUNTER: '/api/counter',
        COUNTER_INCREMENT: '/api/counter/increment',
        COUNTER_RESET: '/api/counter/reset',
        S3_FILES: '/api/s3/files',
        S3_UPLOAD: '/api/s3/upload'
    },
    
    // Configuración de la UI
    UPDATE_INTERVAL: 30000, // 30 segundos
    ANIMATION_DURATION: 300
};

// Variables globales
let updateInterval;
let awsInfo = {};

// Inicialización cuando se carga la página
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 AWS Demo Node.js Site loaded');
    
    // Configurar navegación suave
    setupSmoothScrolling();
    
    // Cargar datos iniciales
    initializeApp();
    
    // Configurar actualizaciones automáticas
    startAutoUpdates();
    
    console.log('✅ Application initialized successfully');
});

// Inicializar la aplicación
async function initializeApp() {
    try {
        console.log('🔄 Initializing application...');
        
        // Verificar estado del servidor
        await checkServerHealth();
        
        // Cargar información de AWS
        await loadAWSInfo();
        
        // Cargar contador de visitas
        await loadVisitCounter();
        
        // Cargar archivos S3
        await loadS3Files();
        
        console.log('✅ Application initialized successfully');
        
    } catch (error) {
        console.error('❌ Error initializing application:', error);
        showError('Error al inicializar la aplicación');
    }
}

// Verificar estado del servidor
async function checkServerHealth() {
    try {
        console.log('🏥 Checking server health...');
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.HEALTH}`);
        const data = await response.json();
        
        if (data.success) {
            updateServerStatus('online', `Servidor activo (${data.version})`);
            updateAPIStatus('online', 'APIs funcionando');
            console.log('✅ Server is healthy');
        } else {
            throw new Error('Server health check failed');
        }
        
    } catch (error) {
        console.error('❌ Server health check failed:', error);
        updateServerStatus('offline', 'Servidor desconectado');
        updateAPIStatus('offline', 'APIs no disponibles');
    }
}

// Cargar información de AWS
async function loadAWSInfo() {
    try {
        console.log('☁️ Loading AWS information...');
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.AWS_INFO}`);
        const data = await response.json();
        
        if (data.success) {
            awsInfo = data.data;
            updateAWSInfo(awsInfo);
            console.log('✅ AWS information loaded');
        } else {
            throw new Error('Failed to load AWS info');
        }
        
    } catch (error) {
        console.error('❌ Error loading AWS info:', error);
        showError('Error cargando información de AWS');
    }
}

// Actualizar información de AWS en la UI
function updateAWSInfo(info) {
    // Actualizar tarjetas de servicios
    const ec2Info = document.getElementById('ec2-info');
    if (ec2Info) {
        ec2Info.textContent = `${info.ec2.instanceId} (${info.ec2.instanceType})`;
    }
    
    const s3Info = document.getElementById('s3-info');
    if (s3Info) {
        s3Info.textContent = `${info.s3.bucketName} (${info.s3.objects} archivos)`;
    }
    
    const iamInfo = document.getElementById('iam-info');
    if (iamInfo) {
        iamInfo.textContent = `${info.iam.roles.length} roles configurados`;
    }
    
    const lambdaInfo = document.getElementById('lambda-info');
    if (lambdaInfo) {
        lambdaInfo.textContent = `${info.lambda.functionName} (${info.lambda.status})`;
    }
    
    // Actualizar footer
    const footerInfo = document.getElementById('aws-info-footer');
    if (footerInfo) {
        footerInfo.innerHTML = `
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; text-align: left;">
                <div><strong>EC2:</strong> ${info.ec2.instanceId} (${info.ec2.status})</div>
                <div><strong>S3:</strong> ${info.s3.bucketName} (${info.s3.size})</div>
                <div><strong>Lambda:</strong> ${info.lambda.functionName}</div>
                <div><strong>Región:</strong> ${info.ec2.region}</div>
            </div>
        `;
    }
}

// Cargar contador de visitas
async function loadVisitCounter() {
    try {
        console.log('📊 Loading visit counter...');
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.COUNTER}`);
        const data = await response.json();
        
        if (data.success) {
            updateCounterDisplay(data.count, data.timestamp);
            console.log('✅ Visit counter loaded:', data.count);
        } else {
            throw new Error('Failed to load counter');
        }
        
    } catch (error) {
        console.error('❌ Error loading counter:', error);
        document.getElementById('visit-count').textContent = 'Error';
    }
}

// Incrementar contador
async function incrementCounter() {
    try {
        console.log('🔄 Incrementing counter...');
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.COUNTER_INCREMENT}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const data = await response.json();
        
        if (data.success) {
            updateCounterDisplay(data.count, data.timestamp);
            animateCounter();
            console.log('✅ Counter incremented to:', data.count);
        } else {
            throw new Error('Failed to increment counter');
        }
        
    } catch (error) {
        console.error('❌ Error incrementing counter:', error);
        showError('Error al incrementar contador');
    }
}

// Obtener contador actual
async function getCounter() {
    await loadVisitCounter();
}

// Resetear contador
async function resetCounter() {
    try {
        if (!confirm('¿Estás seguro de que quieres resetear el contador?')) {
            return;
        }
        
        console.log('🔄 Resetting counter...');
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.COUNTER_RESET}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const data = await response.json();
        
        if (data.success) {
            updateCounterDisplay(data.count, data.timestamp);
            console.log('✅ Counter reset to:', data.count);
        } else {
            throw new Error('Failed to reset counter');
        }
        
    } catch (error) {
        console.error('❌ Error resetting counter:', error);
        showError('Error al resetear contador');
    }
}

// Actualizar display del contador
function updateCounterDisplay(count, timestamp) {
    const countElement = document.getElementById('visit-count');
    const lastUpdateElement = document.getElementById('counter-last-update');
    
    if (countElement) {
        countElement.textContent = count;
    }
    
    if (lastUpdateElement && timestamp) {
        const date = new Date(timestamp);
        lastUpdateElement.textContent = `Última actualización: ${date.toLocaleString()}`;
    }
}

// Animar contador
function animateCounter() {
    const counterElement = document.querySelector('.visit-counter');
    if (counterElement) {
        counterElement.style.transform = 'scale(1.1)';
        setTimeout(() => {
            counterElement.style.transform = 'scale(1)';
        }, APP_CONFIG.ANIMATION_DURATION);
    }
}

// Cargar archivos S3
async function loadS3Files() {
    try {
        console.log('📁 Loading S3 files...');
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.S3_FILES}`);
        const data = await response.json();
        
        if (data.success) {
            updateS3Gallery(data.files);
            updateS3Details(data);
            console.log('✅ S3 files loaded:', data.files.length);
        } else {
            throw new Error('Failed to load S3 files');
        }
        
    } catch (error) {
        console.error('❌ Error loading S3 files:', error);
        showError('Error cargando archivos S3');
    }
}

// Actualizar galería S3
function updateS3Gallery(files) {
    const imageGrid = document.getElementById('image-grid');
    if (!imageGrid) return;
    
    imageGrid.innerHTML = '';
    
    files.forEach((file, index) => {
        const fileElement = document.createElement('div');
        fileElement.className = 'image-placeholder slide-in';
        fileElement.style.animationDelay = `${index * 0.1}s`;
        
        fileElement.innerHTML = `
            <div style="text-align: center;">
                <div style="font-size: 4rem; margin-bottom: 1rem;">📷</div>
                <h4>${file.key}</h4>
                <p>Tamaño: ${formatBytes(file.size)}</p>
                <small>URL: ${file.url}</small>
                <br><br>
                <button onclick="openS3File('${file.url}')" style="font-size: 0.9rem; padding: 0.5rem 1rem;">
                    Ver Archivo
                </button>
            </div>
        `;
        
        imageGrid.appendChild(fileElement);
    });
}

// Actualizar detalles S3
function updateS3Details(data) {
    const s3Details = document.getElementById('s3-details');
    if (s3Details) {
        s3Details.innerHTML = `
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem;">
                <div><strong>Bucket:</strong> ${data.bucket}</div>
                <div><strong>Archivos:</strong> ${data.count}</div>
                <div><strong>Región:</strong> ${awsInfo.s3?.region || 'us-east-1'}</div>
                <div><strong>Última actualización:</strong> ${new Date().toLocaleTimeString()}</div>
            </div>
        `;
    }
}

// Abrir archivo S3
function openS3File(url) {
    window.open(url, '_blank');
}

// Simular subida de archivo
async function simulateUpload() {
    try {
        console.log('📤 Simulating file upload...');
        
        const fileName = `demo-file-${Date.now()}.txt`;
        const fileSize = Math.floor(Math.random() * 10000) + 1000;
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${APP_CONFIG.ENDPOINTS.S3_UPLOAD}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                fileName: fileName,
                fileSize: fileSize
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            console.log('✅ File upload simulated:', data.file);
            alert(`Archivo subido exitosamente:\n${data.file.key}\nTamaño: ${formatBytes(data.file.size)}`);
            
            // Recargar archivos S3
            await loadS3Files();
        } else {
            throw new Error('Failed to simulate upload');
        }
        
    } catch (error) {
        console.error('❌ Error simulating upload:', error);
        showError('Error simulando subida');
    }
}

// Probar API
async function testAPI(endpoint) {
    try {
        console.log('🧪 Testing API:', endpoint);
        
        const response = await fetch(`${APP_CONFIG.API_BASE_URL}${endpoint}`);
        const data = await response.json();
        
        // Mostrar respuesta en el área de respuesta
        const responseElement = document.getElementById('api-response-content');
        if (responseElement) {
            responseElement.textContent = JSON.stringify(data, null, 2);
        }
        
        console.log('✅ API test completed:', endpoint);
        
    } catch (error) {
        console.error('❌ API test failed:', error);
        
        const responseElement = document.getElementById('api-response-content');
        if (responseElement) {
            responseElement.textContent = `Error: ${error.message}`;
        }
    }
}

// Actualizar estado del servidor
function updateServerStatus(status, message) {
    const statusElement = document.getElementById('server-status');
    if (statusElement) {
        statusElement.textContent = message;
        statusElement.className = `status-${status}`;
    }
}

// Actualizar estado de las APIs
function updateAPIStatus(status, message) {
    const statusElement = document.getElementById('api-status');
    if (statusElement) {
        statusElement.textContent = message;
        statusElement.className = `status-${status}`;
    }
}

// Configurar navegación suave
function setupSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Iniciar actualizaciones automáticas
function startAutoUpdates() {
    updateInterval = setInterval(async () => {
        console.log('🔄 Auto-updating data...');
        await checkServerHealth();
        await loadVisitCounter();
    }, APP_CONFIG.UPDATE_INTERVAL);
    
    console.log('⏰ Auto-updates started');
}

// Detener actualizaciones automáticas
function stopAutoUpdates() {
    if (updateInterval) {
        clearInterval(updateInterval);
        updateInterval = null;
        console.log('⏹️ Auto-updates stopped');
    }
}

// Funciones de utilidad
function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function showError(message) {
    console.error('❌', message);
    // En una implementación real, aquí mostrarías un toast o modal
    alert(`Error: ${message}`);
}

function showSuccess(message) {
    console.log('✅', message);
    // En una implementación real, aquí mostrarías un toast o modal
}

// Manejo de eventos de la ventana
window.addEventListener('beforeunload', () => {
    stopAutoUpdates();
});

// Exportar funciones para uso global
window.incrementCounter = incrementCounter;
window.getCounter = getCounter;
window.resetCounter = resetCounter;
window.loadS3Files = loadS3Files;
window.simulateUpload = simulateUpload;
window.testAPI = testAPI;
window.openS3File = openS3File;

console.log('📜 Script loaded successfully');
