#!/bin/bash
set -e  # stop immediately if any command fails

echo "==> Building CSS (Tailwind)..."
export PATH="$PWD/node_modules/.bin:$PATH"
npm run build:css

echo "==> Building site (Hugo)..."
hugo --minify --config config.toml,config.local.toml

echo "==> Syncing to live web root..."
sudo rsync -a --delete /root/raycaparros-site/public/ /var/www/raycaparros.com/raycaparros-site/public/

echo "==> Fixing permissions..."
sudo chown -R nginx:nginx /var/www/raycaparros.com

echo "==> Done! Live at https://raycaparros.com"
echo ""

# --- Git reminder/prompt ---
if [ -n "$(git status --porcelain)" ]; then
  echo "==> You have uncommitted changes:"
  git status --short
  echo ""
  read -p "Commit and push these changes to GitHub now? (y/n): " confirm
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    read -p "Enter a commit message: " commit_msg
    git add .
    git commit -m "$commit_msg"
    git push
    echo "==> Pushed to GitHub."
  else
    echo "==> Skipped. Remember to commit later!"
  fi
else
  echo "==> No uncommitted changes. GitHub is already up to date."
fi
