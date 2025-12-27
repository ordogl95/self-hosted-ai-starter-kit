# Troubleshooting: Network Timeout During Docker Compose

## Issue
You're experiencing `unexpected EOF` errors when running `docker-compose --profile gpu-nvidia up -d`

This happens because:
- The Docling GPU image is **6.26GB** (very large)
- The Ollama image is **2.17GB**
- Together with other services, docker-compose tries to pull ~9GB simultaneously
- Network connection times out during the large Docling pull

## Solution: Staged Pull Approach

I've created a script that pulls images separately to avoid network timeouts.

### Option 1: Run the Automated Script (Recommended)

```bash
setup_ollama_gpu.bat
```

This script will:
1. ✅ Pre-pull Docling image separately (with retry logic)
2. ✅ Pre-pull Ollama image separately
3. ✅ Create Docker volumes
4. ✅ Run docker-compose with GPU profile
5. ✅ Wait for services to start
6. ✅ Show status and next steps

**Expected time: 30-45 minutes** (mostly download time)

---

### Option 2: Manual Step-by-Step

If you prefer to do it manually, follow these steps:

#### Step 1: Stop any existing containers
```bash
docker-compose -f self-hosted-ai-starter-kit/docker-compose.yml --profile gpu-nvidia down
docker system prune -f
```

#### Step 2: Pull Docling image separately (largest image)
```bash
docker pull ghcr.io/docling-project/docling-serve-cu126:main
```

This is **6.26GB** and will take 10-20 minutes depending on your connection.

**If it times out:** Just run the command again. Docker will resume from where it left off.

#### Step 3: Pull Ollama image
```bash
docker pull ollama/ollama:latest
```

#### Step 4: Create Docker volumes
```bash
docker volume create ollama_storage
docker volume create postgres_storage
docker volume create qdrant_storage
docker volume create docling_data
```

#### Step 5: Run docker-compose
```bash
cd self-hosted-ai-starter-kit
docker-compose --profile gpu-nvidia up -d
```

Now all images are already pulled, so it should start immediately without network issues.

---

## If Pulls Keep Failing

### Check Your Network
```bash
ping 1.1.1.1
```

If this fails, you have network connectivity issues.

### Increase Docker Timeout
Edit Docker settings (Windows):
1. Open Docker Desktop
2. Settings → Docker Engine
3. Add this line:
```json
{
  "max-concurrent-downloads": 1,
  "max-concurrent-uploads": 1
}
```

This slows down pulls but makes them more stable on unreliable connections.

### Use a Different Registry Mirror
Docker sometimes times out on the default registry. Try using a mirror:

```bash
docker pull docker.mirrors.sjtug.sjtu.edu.cn/library/ollama:latest
```

Or configure Docker to use a mirror persistently by editing `~/.docker/daemon.json`:
```json
{
  "registry-mirrors": [
    "https://docker.mirrors.sjtug.sjtu.edu.cn"
  ]
}
```

---

## Verify GPU is Working After Setup

Once services are running:

```bash
# Check GPU usage
nvidia-smi

# View Ollama logs
docker logs ollama

# Test Ollama is running
curl http://localhost:11434/api/tags

# Pull a model (uses GPU)
docker exec ollama ollama pull llama3.2

# Monitor GPU while running inference
watch -n 1 nvidia-smi
```

---

## Alternative: Skip Docling (CPU-only) for Faster Setup

If you want to test GPU support quickly without Docling (which is the culprit):

```bash
docker-compose --profile gpu-nvidia --profile cpu up -d
```

Wait, that won't work because of profile conflicts. Instead, edit `docker-compose.yml` and comment out the docling services, then run:

```bash
docker-compose --profile gpu-nvidia up -d
```

This will only run:
- PostgreSQL ✓
- n8n ✓
- Ollama GPU ✓
- Qdrant ✓

And skip Docling entirely, making setup much faster!

---

## Expected Timeline

- **Pre-pull Docling**: 10-20 min (depending on internet speed)
- **Pre-pull Ollama**: 5-10 min
- **Docker Compose startup**: 2-5 min
- **Model download** (optional): 5-10 min for Llama 3.2

**Total: 30-50 minutes** depending on internet connection

---

## Success Indicators

✅ All containers are running:
```bash
docker-compose --profile gpu-nvidia ps
```

✅ GPU is accessible to containers:
```bash
docker run --rm --gpus all nvidia/cuda:12.6.2-runtime-ubuntu24.04 nvidia-smi
```

✅ Ollama API is responding:
```bash
curl http://localhost:11434/api/tags
```

---

## Still Having Issues?

Try these commands to debug:

```bash
# Check Docker daemon logs (Windows)
Get-EventLog -LogName Application -Source Docker

# Check docker-compose version
docker-compose --version

# Clear all Docker cache
docker system prune -a

# Restart Docker Desktop
# (Settings → Restart Docker)
```

Then retry the pull/setup process.
