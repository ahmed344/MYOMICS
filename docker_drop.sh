#!/usr/bin/env bash
# Start an interactive DROP 1.6.1 container (STAR, samtools, Snakemake 7.32).
#
# Host /etc/passwd is mounted so the container user matches the host UID/name,
# but /home/ahmed is not in the image. Snakemake then dies creating
# ~/.cache/snakemake (PermissionError: /home/ahmed). Point HOME at /tmp.
set -euo pipefail

docker run --rm -it \
  --name myomics-drop \
  --hostname drop \
  --user "$(id -u):$(id -g)" \
  -e USER="$(whoami)" \
  -e LOGNAME="$(whoami)" \
  -e HOME=/tmp/myomics_home \
  -e XDG_CACHE_HOME=/tmp/myomics_home/.cache \
  -e XDG_CONFIG_HOME=/tmp/myomics_home/.config \
  --memory=200g \
  --cpus=24 \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -v /home/ahmed/Data/MYOMICS:/workspace/data \
  -v /home/ahmed/Data/HDD/Data/MYOMICS/:/workspace/data_hdd \
  -v /home/ahmed/Repositories/MYOMICS/:/workspace \
  -w /workspace \
  quay.io/biocontainers/drop:1.6.1--pyhdfd78af_0 \
  bash
