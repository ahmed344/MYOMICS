docker run --rm -it \
  --name myomics-drop \
  --hostname drop \
  --user "$(id -u):$(id -g)" \
  -e USER="$(whoami)" \
  -e LOGNAME="$(whoami)" \
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