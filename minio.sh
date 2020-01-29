# Minio
export MINIO_ACCESS_KEY="minio"
export MINIO_SECRET_KEY="miniokey"
mkdir -p /data/beep/boop
/usr/local/bin/minio server /data --address 0.0.0.0:9000 > minio.log 2>&1 &