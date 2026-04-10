## Sync local files to EC2 instance

```sh
rsync --verbose --recursive --archive ~/Documents/Koszul/__Teaching/_Workshops/20260413_Physalia_NGS-course/Epigenomics physalia:
```

## Set up Docker container with RStudio Server and micromamba for NGS workshop

```sh
# ============================================================
# 0. Stop system-wide RStudio Server
# ============================================================
sudo rstudio-server stop
sudo systemctl disable rstudio-server

# ============================================================
# 1. Install Docker
# ============================================================
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# ============================================================
# 2. Pull the image
# ============================================================
sudo docker pull ghcr.io/js2264/ngs-physalia:devel

# ============================================================
# 3. Run the container
# ============================================================
sudo docker stop ngs-workshop 2>/dev/null
sudo docker rm ngs-workshop 2>/dev/null
sudo docker run -d \
    --name ngs-workshop \
    --restart unless-stopped \
    -p 8787:8787 \
    -e PASSWORD=rstudio26 \
    -v /home/ubuntu/Share:/opt/Share:ro \
    ghcr.io/js2264/ngs-physalia:devel

# Wait for container to fully start
sleep 5

# ============================================================
# 3b. Missing touches: 
#    - create a new env with yapc
# ============================================================
sudo docker exec -u root ngs-workshop bash -c \
    'micromamba create -n yapc_env -y -c conda-forge -c bioconda -c nodefaults yapc "numpy<1.24"'
sudo docker exec -u root ngs-workshop bash -c \
    'micromamba run -n yapc_env -- which yapc'

# ============================================================
# 4. Make micromamba + epigenomics env accessible to all users
# ============================================================

# 4a. Copy binary to system-wide location
sudo docker exec -u root ngs-workshop bash -c \
    "cp /root/.local/bin/micromamba /usr/local/bin/micromamba && chmod 755 /usr/local/bin/micromamba"

# 4b. Copy entire micromamba root to shared location
sudo docker exec -u root ngs-workshop bash -c \
    "cp -a /root/micromamba /opt/micromamba && chmod -R a+rX /opt/micromamba"

# 4c. Verify
sudo docker exec -u root ngs-workshop ls /opt/micromamba/envs/epigenomics/bin/ | grep samtools
sudo docker exec -u root ngs-workshop ls /opt/micromamba/envs/yapc_env/bin/ | grep yapc

# ============================================================
# 5. Auto-activate epigenomics env for all RStudio sessions
# ============================================================

# 5a. RStudio R session profile (runs before every R session)
sudo docker exec -u root ngs-workshop bash -c 'cat > /etc/rstudio/rsession-profile << "EOF"
export MAMBA_ROOT_PREFIX=/opt/micromamba
export MAMBA_EXE=/usr/local/bin/micromamba
eval "$(micromamba shell hook -s bash)"
micromamba activate epigenomics
EOF'

# 5b. R environment variables (visible via Sys.getenv() in R)
sudo docker exec -u root ngs-workshop bash -c 'cat >> /usr/local/lib/R/etc/Renviron.site << "EOF"

## Micromamba epigenomics env
MAMBA_ROOT_PREFIX=/opt/micromamba
PATH=/opt/micromamba/envs/epigenomics/bin:${PATH}
EOF'

# 5c. System bashrc (for RStudio Terminal tab)
sudo docker exec -u root ngs-workshop bash -c 'cat >> /etc/bash.bashrc << "EOF"

## Micromamba auto-activate
export MAMBA_ROOT_PREFIX=/opt/micromamba
export MAMBA_EXE=/usr/local/bin/micromamba
eval "$(micromamba shell hook -s bash)"
micromamba activate epigenomics
EOF'

# 5d. System bashrc (for RStudio Terminal tab)
sudo docker exec -u root ngs-workshop bash -c 'cat > /etc/profile.d/micromamba.sh << "EOF"
export MAMBA_ROOT_PREFIX=/opt/micromamba
export MAMBA_EXE=/usr/local/bin/micromamba
eval "$(micromamba shell hook -s bash)"
micromamba activate epigenomics
EOF
chmod 644 /etc/profile.d/micromamba.sh'

# 5e. Fix shebangs in micromamba env binaries to point to correct micromamba location
sudo docker exec -u root ngs-workshop bash -c \
    'find /opt/micromamba/envs/epigenomics/bin/ -type f -exec sed -i "1s|#!/root/micromamba/|#!/opt/micromamba/|g" {} +'
sudo docker exec -u root ngs-workshop head -1 /opt/micromamba/envs/epigenomics/bin/bamCoverage

sudo docker exec -u root ngs-workshop bash -c \
    'find /opt/micromamba/envs/yapc_env/bin/ -type f -exec sed -i "1s|#!/root/micromamba/|#!/opt/micromamba/|g" {} +'
sudo docker exec -u root ngs-workshop head -1 /opt/micromamba/envs/yapc_env/bin/yapc

# ============================================================
# 6. Create 20 users
# ============================================================
for i in $(seq 1 20); do
    sudo docker exec -u root ngs-workshop bash -c \
        "useradd -m -s /bin/bash user${i} && echo 'user${i}:rstudio26' | chpasswd"
done
sudo docker exec -u root ngs-workshop grep user /etc/passwd

# ============================================================
# 6b. Give sudo permissions to rstudio user
# ============================================================
sudo docker exec -u root ngs-workshop bash -c \
    "echo 'rstudio ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rstudio && chmod 440 /etc/sudoers.d/rstudio"
sudo docker exec -u root ngs-workshop su - rstudio -c "sudo whoami"

# ============================================================
# 7. Symlink shared folder into each user's home
# ============================================================
for i in $(seq 1 20); do
    sudo docker exec -u root ngs-workshop bash -c \
        "ln -s /opt/Share /home/user${i}/Share && chown -h user${i}:user${i} /home/user${i}/Share"
done
sudo docker exec -u root ngs-workshop ls -l /home/user*/Share

# ============================================================
# 7b. Also symlink book content (/opt/BiocBook/pages/*) to `notebooks/` in users' home
# ============================================================
for i in $(seq 1 20); do
    sudo docker exec -u root ngs-workshop bash -c \
        "ln -s /opt/BiocBook/pages /home/user${i}/notebooks && chown -h user${i}:user${i} /home/user${i}/notebooks"
done
sudo docker exec -u root ngs-workshop ls -l /home/user*/notebooks

# ============================================================
# 8. Restart RStudio Server
# ============================================================
sudo docker exec -u root ngs-workshop rstudio-server restart

# ============================================================
# 9. Verify everything works
# ============================================================
echo "--- Checking micromamba binary ---"
sudo docker exec -u root ngs-workshop su - user1 -c "which micromamba"

echo "--- Checking env activation in bash ---"
sudo docker exec -u root ngs-workshop su - user1 -c "micromamba info | grep environment"

echo "--- Checking tools from epigenomics env are on PATH ---"
sudo docker exec -u root ngs-workshop su - user1 -c "which python 2>/dev/null; which samtools 2>/dev/null; which bowtie2 2>/dev/null"

echo "--- Checking R sees the right PATH ---"
sudo docker exec -u root ngs-workshop su - user1 -c \
    'R --vanilla -e "system(\"echo \$CONDA_DEFAULT_ENV\", intern=TRUE)"'

echo ""
echo "============================================"
echo " Done! Access RStudio at:"
echo " http://<EC2-PUBLIC-IP>:8787"
echo " Users: user1-user20 / Password: rstudio26"
echo "============================================"

# ============================================================
# 10. Cleanup (if/when needed)
# ============================================================
# Attach terminal to running container
sudo docker exec -it -u rstudio ngs-workshop /bin/bash

# Stop and remove the current container
sudo docker restart ngs-workshop

# Stop and remove the current container
sudo docker stop ngs-workshop
sudo docker rm ngs-workshop
```

