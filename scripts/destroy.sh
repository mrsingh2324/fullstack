#!/bin/bash
set -e

echo "=== MERN Stack Destroy Script ==="

cd "$(dirname "$0")/../terraform"

echo "This will destroy all resources. Are you sure?"
read -p "Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo "Destroying resources..."
terraform destroy -auto-approve

echo "=== Destroy Complete ==="
