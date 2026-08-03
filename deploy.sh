#!/bin/bash
set -e  # stop immediately if any command fails

echo "==> Building CSS (Tailwind)..."
export PATH="$PWD/node_modules/.bin:$PATH"
npm run build:css

echo "==> Building site (Hugo)..."
hugo --minify

echo "==> Syncing to live web root..."
sudo rsync -a --delete /root/raycaparros-site/public/ /var/www/raycaparros.com/raycaparros-site/public/

echo "==> Fixing permissions..."
sudo chown -R nginx:nginx /var/www/raycaparros.com

echo "==> Done! Live at https://raycaparros.com"
