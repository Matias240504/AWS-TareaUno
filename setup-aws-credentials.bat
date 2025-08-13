@echo off
echo 🔑 Configuracion de Credenciales AWS para Windows
echo ================================================

REM Verificar si AWS CLI esta instalado
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI no esta instalado.
    echo.
    echo 📥 Descargalo desde: https://aws.amazon.com/cli/
    echo    O ejecuta: winget install Amazon.AWSCLI
    echo.
    pause
    exit /b 1
)

echo ✅ AWS CLI encontrado
aws --version
echo.

echo 📋 Necesitas las siguientes credenciales de tu cuenta AWS:
echo    1. Access Key ID ^(empieza con AKIA...^)
echo    2. Secret Access Key ^(cadena larga alfanumerica^)
echo.
echo 🔗 Para obtenerlas:
echo    1. Ve a AWS Console → IAM → Users
echo    2. Crea usuario 'aws-demo-user' con acceso programatico
echo    3. Asigna permisos: EC2FullAccess, S3FullAccess, IAMFullAccess, LambdaFullAccess
echo    4. Descarga las credenciales
echo.

set /p continue="¿Ya tienes las credenciales? (y/N): "
if /i not "%continue%"=="y" (
    echo Ve a AWS Console primero y obten las credenciales.
    echo Luego ejecuta este script nuevamente.
    pause
    exit /b 0
)

echo.
echo 🔧 Configurando AWS CLI...
echo.
echo Ingresa tus credenciales AWS:

REM Configurar AWS CLI interactivamente
aws configure

echo.
echo 🧪 Probando conexion...

REM Verificar configuracion
aws sts get-caller-identity >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ ¡Credenciales configuradas correctamente!
    echo.
    echo 📊 Informacion de tu cuenta AWS:
    aws sts get-caller-identity
    echo.
    echo 🚀 ¡Listo para desplegar!
    echo Ejecuta en WSL/Git Bash: ./deploy-aws.sh
    echo O usa AWS CloudShell desde AWS Console
) else (
    echo ❌ Error en la configuracion de credenciales.
    echo Verifica que:
    echo    - Las credenciales sean correctas
    echo    - El usuario tenga los permisos necesarios
    echo    - Tu conexion a internet funcione
)

echo.
pause
