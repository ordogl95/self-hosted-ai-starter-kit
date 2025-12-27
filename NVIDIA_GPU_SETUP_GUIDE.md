# NVIDIA Container Toolkit Setup Guide for Ollama

## Current System Status ✅

**All components are properly installed and configured:**

- ✅ NVIDIA GPU: GeForce RTX 3080 (10GB VRAM)
- ✅ NVIDIA Driver: Version 581.63
- ✅ CUDA Version: 13.0
- ✅ Docker: Version 28.5.1
- ✅ NVIDIA Container Runtime: Installed and active
- ✅ Docker-Compose: GPU profiles configured

---

## Quick Start: Run Ollama with GPU Support

### Option 1: Using Docker Compose (Recommended)

Navigate to your project directory and run:

```bash
cd self-hosted-ai-starter-kit
docker-compose --profile gpu-nvidia up -d
```

This will:
- Start the PostgreSQL database
- Start n8n with document processing
- Start **Ollama with GPU support** (ollama-gpu service)
- Pull the Llama 3.2 model automatically
- Start Docling with GPU support for document processing

### Option 2: Run Ollama Container Directly

```bash
docker run -d --name ollama --gpus all -p 11434:11434 -v ollama_storage:/root/.ollama ollama/ollama:latest
```

### Option 3: Pull and Run a Model

Once Ollama is running, pull a model:

```bash
docker exec ollama ollama pull llama3.2
```

Or for other models:
```bash
docker exec ollama ollama pull mistral
docker exec ollama ollama pull neural-chat
```

---

## Verify GPU is Being Used

Check that your GPU is being utilized:

```bash
# Check GPU usage (run on host)
nvidia-smi

# Expected output should show ollama process using GPU memory
```

Or check from within the container:

```bash
docker exec ollama nvidia-smi
```

---

## Docker Compose Configuration Review

Your `docker-compose.yml` already includes these GPU-optimized services:

### Ollama with GPU
```yaml
ollama-gpu:
  profiles: ["gpu-nvidia"]
  image: ollama/ollama:latest
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

### Docling with GPU (CUDA 12.6)
```yaml
docling-gpu:
  profiles: ["gpu-nvidia"]
  image: ghcr.io/docling-project/docling-serve-cu126:main
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
```

---

## Testing GPU Acceleration

### Test 1: Quick GPU Test
```bash
docker run --rm --gpus all nvidia/cuda:12.6.2-runtime-ubuntu24.04 nvidia-smi
```

**Expected Output:** Shows your RTX 3080 with current GPU/Memory info

### Test 2: Ollama with Model
```bash
# Start Ollama
docker run -d --name ollama --gpus all -p 11434:11434 ollama/ollama

# Pull a model (will use GPU for inference)
docker exec ollama ollama pull llama3.2

# Test inference
docker exec ollama ollama run llama3.2 "What is machine learning?"
```

### Test 3: Monitor GPU Usage While Running
```bash
# In one terminal, keep monitoring GPU
watch -n 1 nvidia-smi

# In another terminal, run inference
docker exec ollama ollama run llama3.2 "Generate a poem about AI"
```

---

## Optimization Tips for RTX 3080

Your RTX 3080 has 10GB of VRAM. Here are recommendations:

| Model | VRAM Required | Recommended Settings |
|-------|---------------|----------------------|
| Llama 3.2 1B | ~2-3 GB | Full GPU support recommended |
| Llama 3.2 8B | ~7-8 GB | Full GPU support - keeps fast |
| Mistral 7B | ~6-7 GB | GPU with some safeguards |
| Neural Chat 7B | ~5-6 GB | Great balance of speed & VRAM |

**For best performance with multiple models:**
- Use smaller quantized versions (Q4, Q5)
- Or use mixed precision (will use CPU for some layers)

---

## Troubleshooting

### Issue: "GPU not detected in container"
**Solution:** Verify NVIDIA runtime is set:
```bash
docker run -it --rm --gpus all nvidia/cuda:12.6.2-runtime-ubuntu24.04 nvidia-smi
```

### Issue: "Out of GPU memory"
**Solution:** 
- Use a smaller model: `ollama pull mistral` instead of larger variants
- Or reduce batch size in application settings
- Check current usage: `nvidia-smi`

### Issue: "Ollama running on CPU instead of GPU"
**Solution:** 
- Ensure you're using the `gpu-nvidia` profile: `--profile gpu-nvidia`
- Check logs: `docker logs ollama`
- Verify GPU is visible: `docker run --rm --gpus all nvidia/cuda:12.6.2-runtime-ubuntu24.04 nvidia-smi`

---

## Useful Commands

```bash
# Check all GPU-related services
docker-compose --profile gpu-nvidia config | grep -A 10 "gpu"

# View Ollama logs
docker logs -f ollama

# Check current GPU usage
nvidia-smi

# List available models in Ollama
docker exec ollama ollama list

# Remove a model
docker exec ollama ollama rm llama3.2

# Interactive Ollama shell
docker exec -it ollama ollama run llama3.2
```

---

## API Usage

Once Ollama is running on GPU, you can use it via API:

```bash
# Generate response
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is GPU acceleration important?",
  "stream": false
}'

# Chat endpoint
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "stream": false
}'
```

---

## Summary

✅ **Your system is fully ready for GPU-accelerated Ollama!**

**Next Steps:**
1. Run: `docker-compose --profile gpu-nvidia up -d`
2. Wait for services to start (~1-2 minutes)
3. Access Ollama API at `http://localhost:11434`
4. Monitor GPU: `nvidia-smi` or `watch nvidia-smi`

**Resources:**
- Ollama Docs: https://ollama.ai
- NVIDIA Docker Docs: https://github.com/NVIDIA/nvidia-docker
- Your RTX 3080 supports CUDA 12.6+ for maximum compatibility
