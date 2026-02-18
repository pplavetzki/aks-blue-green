#!/bin/sh
SECRET_DIR="/mnt/secrets"
echo "=== Key Vault Secret Test ==="
for f in "$SECRET_DIR"/*; do
  echo "$(basename $f): $(cat $f)"
done
echo "=== Done ==="
sleep 3600  # keep pod alive for inspection
