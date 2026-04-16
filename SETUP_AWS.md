## Sync local files to EC2 instance

```sh
rsync --progress --verbose --recursive --archive maestro:~/Projects/20260413_Physalia-Epigenomics/Share physalia:
rsync --progress --verbose --recursive --archive Share physalia:
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
# 4. Verify micromamba is accessible (baked into image)
# ============================================================
sudo docker exec -u root ngs-workshop ls /opt/micromamba/envs/epigenomics/bin/ | grep samtools
sudo docker exec -u root ngs-workshop ls /opt/micromamba/envs/pairtools_env/bin/ | grep pairtools
sudo docker exec -u root ngs-workshop ls /opt/micromamba/envs/yapc_env/bin/ | grep yapc

# ============================================================
# 5. Create 20 users
# ============================================================
for i in $(seq 1 20); do
    sudo docker exec -u root ngs-workshop bash -c \
        "useradd -m -s /bin/bash user${i} && echo 'user${i}:rstudio26' | chpasswd"
done
sudo docker exec -u root ngs-workshop grep user /etc/passwd

# ============================================================
# 5b. Give sudo permissions to rstudio user
# ============================================================
sudo docker exec -u root ngs-workshop bash -c \
    "echo 'rstudio ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rstudio && chmod 440 /etc/sudoers.d/rstudio"
sudo docker exec -u root ngs-workshop su - rstudio -c "sudo whoami"

# ============================================================
# 6. Symlink shared folder into each user's home
# ============================================================
for i in $(seq 1 20); do
    sudo docker exec -u root ngs-workshop bash -c \
        "ln -s /opt/Share /home/user${i}/Share && chown -h user${i}:user${i} /home/user${i}/Share"
done
sudo docker exec -u root ngs-workshop ls -l /home/user*/Share

# ============================================================
# 6b. Also symlink book content (/opt/BiocBook/pages/*) to `notebooks/` in users' home
# ============================================================
for i in $(seq 1 20); do
    sudo docker exec -u root ngs-workshop bash -c \
        "ln -s /opt/BiocBook/pages/ /home/user${i}/notebooks && chown -h user${i}:user${i} /home/user${i}/notebooks"
done
sudo docker exec -u root ngs-workshop ls -l /home/user20/notebooks/

# ============================================================
# 7. Restart RStudio Server
# ============================================================
sudo docker exec -u root ngs-workshop rstudio-server restart

# ============================================================
# 8. Verify everything works
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

echo "--- Checking different softares as user20 ---"
for tool in samtools bowtie2 bamCoverage trim_galore yapc pairtools hicstuff chromosight bwa-mem2 xstreme bedtools; do
    sudo docker exec -u root ngs-workshop su - user20 -c \
        "echo -n \Checking $tool: \ && ${tool} --help 2>&1 | head"
done

echo ""
echo "============================================"
echo " Done! Access RStudio at:"
echo " http://<EC2-PUBLIC-IP>:8787"
echo " Users: user1-user20 / Password: rstudio26"
echo "============================================"

# ============================================================
# 9. Cleanup (if/when needed)
# ============================================================
# Attach terminal to running container
sudo docker exec -it -u rstudio ngs-workshop /bin/bash

# Stop and remove the current container
sudo docker restart ngs-workshop

# Stop and remove the current container
sudo docker stop ngs-workshop
sudo docker rm ngs-workshop
```

