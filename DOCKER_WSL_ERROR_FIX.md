# Docker Desktop WSL Error Fix

## Error Message
```
DockerDesktop/Wsl/ExecError: 
c:\windows\system32\wsl.exe --unmount docker_data.vhdx: exit status 0xffffffff
```

## What This Means
This is a **WSL2 (Windows Subsystem for Linux 2) disk issue**, not an NVIDIA problem. Docker Desktop is having trouble managing the virtual disk that stores container data.

---

## Quick Fix (Try This First)

### Step 1: Restart Docker Desktop Completely
```bash
# Close Docker Desktop from system tray
# Wait 10 seconds
# Reopen Docker Desktop

# Or from PowerShell (as Administrator):
Restart-Service com.docker.service
```

### Step 2: Check Disk Space
```bash
# Check available disk space on your C: drive
Get-Volume C
```

**Issue:** If C: drive has less than **5GB free**, this causes Docker/WSL issues.
**Solution:** Free up space by:
- Deleting temporary files: `Temp` and `%LocalAppData%\Temp`
- Running: `Disk Cleanup` utility
- Removing old Docker images: `docker image prune -a`

### Step 3: Reset Docker/WSL Integration
```bash
# In PowerShell (as Administrator):
wsl --list --verbose

# If WSL shows an error, try:
wsl --shutdown

# Wait 5 seconds, then restart Docker Desktop
```

---

## If Quick Fix Doesn't Work

### Nuclear Option 1: Reset WSL (Keep Docker Data)

```powershell
# PowerShell as Administrator

# Stop Docker
Stop-Service docker

# Shutdown WSL
wsl --shutdown

# Wait 10 seconds

# Start Docker again from GUI
```

Then wait 5 minutes for Docker to reinitialize.

### Nuclear Option 2: Reset Docker Desktop

1. **Backup your work** (especially any scripts/configs in `self-hosted-ai-starter-kit`)
2. Open Docker Desktop
3. Go to **Settings → General**
4. Click **"Reset to Factory Defaults"**
5. Restart your computer
6. Restart Docker Desktop

This will:
- Clear Docker images and containers ⚠️
- Reset WSL configuration
- Fix most WSL/Docker integration issues

### Nuclear Option 3: Reinstall Docker Desktop

If reset doesn't work:

1. **Uninstall Docker Desktop:**
   - Settings → Apps → Apps & Features
   - Find "Docker Desktop"
   - Click "Uninstall"
   - Restart computer

2. **Download Fresh:**
   - Go to https://www.docker.com/products/docker-desktop
   - Download latest version
   - Install fresh

3. **Verify Installation:**
   ```bash
   docker --version
   docker run --rm hello-world
   ```

---

## Verify Docker/WSL Health

Run these commands to check everything:

```powershell
# Check WSL status
wsl --list --verbose

# Check Docker daemon
docker ps

# Check Docker version
docker --version

# Test GPU with Docker
docker run --rm --gpus all nvidia/cuda:12.6.2-runtime-ubuntu24.04 nvidia-smi

# Test basic docker-compose
docker-compose --version
```

All should succeed without errors.

---

## After Fixing Docker

Once Docker is working again, **do NOT immediately try the full docker-compose command**. Instead:

### Step 1: Test Ollama Alone
```bash
docker run -d --name ollama-test --gpus all -p 11434:11434 ollama/ollama:latest
```

Wait 30 seconds, then:
```bash
curl http://localhost:11434/api/tags
```

Should return JSON with no errors.

### Step 2: Pre-pull Images Separately
```bash
# Pull Docling (the problematic one)
docker pull ghcr.io/docling-project/docling-serve-cu126:main

# Pull Ollama
docker pull ollama/ollama:latest
```

**Note:** These may take 20-30 minutes each. If they fail, you still have Docker/WSL issues.

### Step 3: Then Run Docker Compose
```bash
cd self-hosted-ai-starter-kit
docker-compose --profile gpu-nvidia up -d
```

---

## Alternative: Use Docker via WSL 2 Native

Instead of Docker Desktop, you can install Docker directly in WSL2:

```bash
# In WSL 2 terminal (not PowerShell)
sudo apt-get update
sudo apt-get install docker.io

# Test
sudo docker run hello-world
```

This sometimes works better for stability, but requires more setup.

---

## Prevent This Error in Future

### Docker Desktop Settings Optimization

1. Open Docker Desktop
2. Settings → Resources
3. Set:
   - **CPUs:** 4-6 (not max)
   - **Memory:** 6-8GB (not max)
   - **Disk image size:** 100GB (or what you have free)
   - **Swap:** 2GB

4. Settings → Docker Engine
   - Add:
   ```json
   {
     "max-concurrent-downloads": 2,
     "storage-driver": "overlay2",
     "log-driver": "json-file"
   }
   ```

5. Settings → WSL Integration
   - Enable WSL 2 integration
   - Select your WSL distributions

---

## Did This Fix It?

Once Docker is working, test with:

```bash
docker run --rm --gpus all nvidia/cuda:12.6.2-runtime-ubuntu24.04 nvidia-smi
```

**Expected:** Shows your RTX 3080 GPU ✅

**If still failing:** Let me know the exact error and we'll debug further.

---

## Summary of Fixes (in order of severity)

1. ✅ Restart Docker Desktop (10 seconds)
2. ✅ Free up disk space (varies)
3. ✅ Shutdown WSL and restart (2 minutes)
4. ⚠️ Reset Docker to Factory Defaults (5 minutes + restart)
5. ⚠️ Uninstall and reinstall Docker (20 minutes)

**Start with #1, escalate if needed.**
