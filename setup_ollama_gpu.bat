@echo off
REM Setup Ollama with GPU - Staged approach to avoid timeout issues
REM This script pulls large images separately to avoid network timeouts

echo.
echo ===================================================
echo OLLAMA GPU SETUP - Staged Docker Pull
echo ===================================================
echo.

REM Change to project directory
cd d/:self-hosted-ai-starter-kit

REM Step 1: Pre-pull the docling image (largest, most likely to timeout)
echo.
echo [STEP 1] Pre-pulling Docling GPU image (6.2GB)...
echo This may take 10-15 minutes. Please be patient.
echo.

docker pull ghcr.io/docling-project/docling-serve-cu126:main
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Docling pull encountered an issue, retrying...
    timeout /t 5 /nobreak
    docker pull ghcr.io/docling-project/docling-serve-cu126:main
)

REM Step 2: Pre-pull the ollama image
echo.
echo [STEP 2] Pre-pulling Ollama image (2.2GB)...
echo.
docker pull ollama/ollama:latest

REM Step 3: Create volumes
echo.
echo [STEP 3] Creating Docker volumes...
echo.
docker volume create ollama_storage 2>nul
docker volume create postgres_storage 2>nul
docker volume create qdrant_storage 2>nul
docker volume create docling_data 2>nul

REM Step 4: Start docker-compose
echo.
echo [STEP 4] Starting services with docker-compose...
echo.
docker-compose --profile gpu-nvidia up -d

echo.
echo ===================================================
echo SETUP COMPLETE!
echo ===================================================
echo.
echo Waiting for services to initialize (60 seconds)...
timeout /t 60 /nobreak

echo.
echo Checking service status:
docker-compose --profile gpu-nvidia ps

echo.
echo ===================================================
echo NEXT STEPS:
echo ===================================================
echo.
echo 1. Monitor GPU usage:
echo    nvidia-smi
echo.
echo 2. View Ollama logs:
echo    docker logs -f ollama
echo.
echo 3. Test Ollama API:
echo    curl http://localhost:11434/api/tags
echo.
echo 4. Pull a model:
echo    docker exec ollama ollama pull llama3.2
echo.
echo 5. Test inference:
echo    docker exec ollama ollama run llama3.2 "Hello!"
echo.
pause
