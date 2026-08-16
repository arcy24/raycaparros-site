# Building a Career Portfolio Site From Scratch
### Domain to Server to Hugo to CareerCanvas Theme to Content to Live Deploy

This guide documents the complete process used to build raycaparros.com and charisserosecaparros.com — two independent portfolio sites hosted on the same Linux server, using Hugo and the CareerCanvas theme.

Companion video series: "Building My Career Portfolio From Scratch" (Parts 1-3 on YouTube).

## Overview

| Stage | What happens |
|---|---|
| 1. Domain | Register a domain name |
| 2. Cloudflare | Add domain as a Cloudflare zone |
| 3. Server | Set up Linux VPS with nginx, Node.js, Hugo |
| 4. DNS | Point domain at server IP |
| 5. Nginx + SSL | Virtual hosting + HTTPS |
| 6. Hugo + Theme | Scaffold site + CareerCanvas theme |
| 7. Config | config.toml (public) + config.local.toml (private) |
| 8. Content | Real About/Experience/Skills/Contact content |
| 9. Deploy | Production build + live web root, or deploy.sh |

## 1. Domain Registration

Register your domain through any registrar (~$10-15/year). Example: charisserosecaparros.com.

Design decision: each site gets its own independent domain, not a subdomain of a company or another site. Each domain is its own brand, owned outright, portable if the underlying platform ever changes.

## 2. Cloudflare Setup

1. Add the domain to Cloudflare as its own zone (Cloudflare -> Add a Site).
2. Cloudflare scans existing DNS records, then gives you a set of nameservers.
3. Update the nameservers at your registrar to point to Cloudflare.
4. Propagation can take minutes to hours.

Each domain gets its own Cloudflare zone, even when multiple domains share the same server. Zones don't know about each other; DNS, SSL, and security settings are all independent per domain.

## 3. Server Setup

Using a Linux VPS (Rocky Linux in this build), connected via SSH.

    cat /etc/os-release
    sudo dnf install -y git
    git --version
    sudo dnf install -y nginx
    sudo systemctl enable --now nginx

    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    sudo firewall-cmd --list-services
    sudo dnf module install -y nodejs:22
    node --version
    sudo dnf install -y rsync
    curl -4 ifconfig.me

Node 22+ is required, not 20 — Node 20 causes a cryptic Hugo PostCSS pipeline error later.

## 4. Connecting DNS to the Server

In the domain's Cloudflare zone -> DNS -> Records, add:

- @ (root) A record -> server IP, Proxied (orange cloud)
- www A record -> server IP, Proxied (orange cloud)

AAAA records: if an old host left behind an AAAA (IPv6) record pointing elsewhere, either delete it or update it to match — otherwise IPv6-capable visitors may still reach the old server while IPv4 visitors reach the new one.

## 5. Nginx Virtual Hosting + SSL

Virtual hosting means one server running multiple independent websites, each matched by hostname (server_name), each with its own web root and SSL certificate.

    sudo mkdir -p /var/www/yourdomain.com/public
    sudo chown -R nginx:nginx /var/www/yourdomain.com

Create a minimal placeholder index.html with meta charset UTF-8 declared, and use HTML entities like &mdash; instead of literal special characters — otherwise browsers may misread the encoding and render garbled characters.

### SSL - Cloudflare Origin CA Certificate

Since traffic is fully proxied through Cloudflare, use a Cloudflare Origin CA certificate instead of Certbot — 15-year validity, no renewal cron job needed. Origin CA certs are per-zone/per-domain — you cannot reuse one cert across two different domains, even on the same server.

Cloudflare Dashboard -> your domain's zone -> SSL/TLS -> Origin Server -> Create Certificate (RSA 2048, 15-year validity, covers root + wildcard).

    sudo mkdir -p /etc/nginx/ssl
    sudo chmod 600 /etc/nginx/ssl/yourdomain.key

Save the Origin Certificate and Private Key into yourdomain.pem and yourdomain.key respectively under /etc/nginx/ssl/.

### Nginx server block

Create /etc/nginx/conf.d/yourdomain.conf with two server blocks: one on port 80 that redirects to https, and one on port 443 with ssl_certificate and ssl_certificate_key pointing to the files above, root pointing to /var/www/yourdomain.com/public, and try_files $uri $uri/ =404.

    sudo nginx -t
    sudo systemctl reload nginx

Then in Cloudflare -> SSL/TLS -> Overview, set the mode to Full (Strict) now that a real cert is on the origin.

Default-server gotcha: if you host multiple sites on one nginx box and none of them explicitly declares default_server, nginx falls back to whichever conf.d file loads first alphabetically — meaning an unmatched hostname could accidentally serve a different site's content. Fix by adding an explicit catch-all config file (e.g. 00-default.conf) with listen 80 default_server and listen 443 ssl default_server blocks that just return 444.

Permissions gotcha: if your project lives under /root/, nginx (running as a non-root nginx user) cannot traverse into /root/ even if the files inside are readable. Always serve from /var/www/yourdomain.com/public, never point root directly at a folder under /root/.

## 6. Hugo + CareerCanvas Theme Scaffolding

### Install Hugo (extended build - required for Sass/SCSS)

    cd /tmp
    HUGO_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep tag_name | sed -E 's/.*v([^"]+).*/\1/')
    curl -LO https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz
    tar -xzf hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz
    sudo mv hugo /usr/local/bin/
    hugo version

Confirm the word "extended" appears in the version output — CareerCanvas needs it or theme styling silently fails to build.

### Create a GitHub repo for the site

Empty repo (no README/gitignore/license) so a local git init push won't conflict. Each site gets its own independent repo, even if sharing server infrastructure.

    ssh-keygen -t ed25519 -C "you@example.com"
    cat ~/.ssh/id_ed25519.pub

Add this public key to GitHub under Settings -> SSH and GPG keys -> New SSH key, then test with:

    ssh -T git@github.com

### Scaffold the project

    cd ~
    hugo new site yoursite-site
    cd yoursite-site
    git init
    git branch -m main
    git submodule add https://github.com/felipecordero/careercanvas.git themes/careercanvas

That last line pulls in the CareerCanvas theme as a git submodule — tracked as its own linked repo, not copy-pasted in.

### The Reference Implementation trick

Many polished Hugo themes (CareerCanvas included) aren't pure Hugo — they need a companion Node.js/Tailwind build pipeline. Rather than guessing at config, clone the theme author's own reference implementation (a full example site) as a sibling folder and copy just the build tooling.

    cd ~
    git clone https://github.com/felipecordero/felipecordero.github.io.git
    cd ~/yoursite-site
    cp ../felipecordero.github.io/package.json .
    cp ../felipecordero.github.io/package-lock.json .
    cp ../felipecordero.github.io/tailwind.config.js .

    cp ../felipecordero.github.io/postcss.config.js .
    cp ../felipecordero.github.io/.gitignore .
    cp -r ../felipecordero.github.io/i18n .
    node --version
    npm install

Node version gotcha: this build pipeline needs Node 22.15+. Node 20 causes a cryptic PostCSS error.

npm install does NOT install Node.js itself — Node/npm must already exist on the machine. npm install just installs the project's dependencies listed in package.json into node_modules/.

If the postcss binary is missing after npm install (binary with name postcss not found in PATH), re-run npm install clean — a partial/interrupted install can silently skip devDependencies like postcss-cli. Verify with: ls node_modules/.bin/ | grep postcss

## 7. Configuration - config.toml (public) vs config.local.toml (private)

Critical step - always check the theme's own example config first, rather than guessing field names:

    cat themes/careercanvas/example-config.toml

Field names must match exactly what the theme's templates expect. Getting this wrong causes silent blank sections or template errors like: can't evaluate field url in type interface {}

Real bug hit during this build: the hero section's name uses two SEPARATE fields - Site.Params.firstName and Site.Params.lastName - NOT a single name field. Missing these renders the name area completely blank with no error thrown. Always grep the actual partial template rather than assuming one name field covers everything.

### Public config.toml (safe to commit - no secrets or personal contact info)

    theme = "careercanvas"
    baseURL = "https://yourdomain.com"
    title = "Your Name"

    [languages.en.params]
      tagline = "Your one-line tagline."
      hero_description = "Short bio."
      hero_location = "City, State"

    [params]
      name = "Your Full Name"
      firstName = "Your"
      lastName = "Full Name"
      profile_image = "/images/your-photo.jpg"
      resume_url = "/files/your-resume.pdf"
      github_url = "https://github.com/yourusername"

      [[params.social]]
        icon = "github"
        url = "https://github.com/yourusername"

    [security]
      [security.exec]
        allow = ['^(dart-)?sass(-embedded)?$', '^go$', '^npx$', '^postcss$', '^node$']
      [security.node.permissions]
        disable = true

This security block is required or Hugo's sandbox blocks the PostCSS and Node build process.

### Private config.local.toml (gitignored - holds PII + secrets)

    [params]
      email = "you@example.com"
      pexelsapikey = "YOUR_PEXELS_KEY_HERE"

Rule of thumb: anything safe to share publicly goes in config.toml. Anything personal or secret (email, phone, API keys) goes in config.local.toml, which must be in .gitignore.

Confirm config.local.toml is actually ignored before ever committing:

    git check-ignore -v config.local.toml

Run the site locally with both files merged:

    export PATH="$PWD/node_modules/.bin:$PATH"
    hugo server --config config.toml,config.local.toml --disableFastRender --bind 0.0.0.0 --port 1314

Use a different --port if another Hugo dev server is already running on the same box for a different site.

## 8. Content

Create real content pages under content/en/. CareerCanvas's homepage pulls each section from a matching page via Site.GetPage "sectionname":

- content/en/about.md - needs intro, study, passion_title, passion_text, mix, personal, and a quickfacts list (each with icon, title, value)
- content/en/contact.md - needs intro (front matter) plus a markdown body
- content/en/skills.md, experience.md, technical.md, testimonials.md - each needs at minimum title plus intro; real data can be filled in later

Placeholder pattern: if a section isn't ready yet, still create the page with just title plus a short intro like "Coming soon!" - this renders a clean heading and one-line message instead of a broken/blank section, since these theme sections wrap their entire body in a with block and render nothing if the page doesn't exist.

## 8. Content

Create real content pages under content/en/. CareerCanvas's homepage pulls each section from a matching page via Site.GetPage "sectionname":

- content/en/about.md - needs intro, study, passion_title, passion_text, mix, personal, and a quickfacts list (each with icon, title, value)
- content/en/contact.md - needs intro (front matter) plus a markdown body
- content/en/skills.md, experience.md, technical.md, testimonials.md - each needs at minimum title plus intro; real data can be filled in later

Placeholder pattern: if a section isn't ready yet, still create the page with just title plus a short intro like "Coming soon!" - this renders a clean heading and one-line message instead of a broken/blank section, since these theme sections wrap their entire body in a with block and render nothing if the page doesn't exist.

Watch for unconditional elements inside a "with" block - e.g. CareerCanvas's Experience timeline renders a vertical line/dot divider even with zero entries, because that divider sits outside the range loop over positions. Fix by wrapping it in its own "if positions" check, overridden via a local copy in your own layouts/partials/ folder (never edit the theme submodule directly - copy the file into your site's layouts/partials/ of the same name, which Hugo automatically prefers over the theme's version).

Optional field - LinkedIn button: CareerCanvas's About section unconditionally renders a "Connect on LinkedIn" button. If you don't set linkedin_url, this renders as a broken empty link. Fix with a local override wrapping it in an "if linkedin_url" check.

Optional - disabling the contact form: if you don't have a Formspree endpoint configured yet, the Send Message form will silently fail with "Contact form not configured" when submitted. Rather than ship a broken form, override the contact partial locally to remove the form column and keep only the Contact Information card until a real Formspree endpoint is ready.

Curate content, don't dump everything: the Experience section doesn't need a full exhaustive history - that's what the linked resume PDF (View CV) is for.

## 9. Production Build & Deploy

    cd ~/yoursite-site
    export PATH="$PWD/node_modules/.bin:$PATH"
    hugo --gc --minify --config config.toml,config.local.toml

This generates a real static public/ folder (minified, fingerprinted assets) - different from hugo server's dev-mode preview. Rebuilding Hugo doesn't require "restarting" anything - it's a one-time static file generation, not a running process.

Back up the current live version first:

    sudo cp -r /var/www/yourdomain.com/public /var/www/yourdomain.com/public.backup-$(date +%Y%m%d-%H%M)

Deploy the new build:

    sudo rm -rf /var/www/yourdomain.com/public/*
    sudo cp -r ~/yoursite-site/public/* /var/www/yourdomain.com/public/
    sudo chown -R nginx:nginx /var/www/yourdomain.com/public
    sudo nginx -t
    sudo systemctl reload nginx

Visit https://yourdomain.com (hard refresh to bypass caching) to confirm the live site.

### One-command deploy script

Once this becomes routine, save it as a script so future updates are a single command. Create a file called deploy.sh with:

    #!/bin/bash
    set -e
    echo "Building site (Hugo)..."
    export PATH="$PWD/node_modules/.bin:$PATH"
    hugo --gc --minify --config config.toml,config.local.toml
    echo "Backing up current live version..."
    sudo cp -r /var/www/yourdomain.com/public /var/www/yourdomain.com/public.backup-$(date +%Y%m%d-%H%M)

    echo "Syncing to live web root..."
    sudo rsync -a --delete ~/yoursite-site/public/ /var/www/yourdomain.com/public/
    echo "Fixing permissions..."
    sudo chown -R nginx:nginx /var/www/yourdomain.com
    echo "Reloading nginx..."
    sudo nginx -t && sudo systemctl reload nginx
    echo "Done! Live at https://yourdomain.com"

Make it executable with: chmod +x deploy.sh

From then on, publishing any change is just: ./deploy.sh

## Repo & Privacy Notes

- Repos are public for teaching purposes, matching this project's "build in public" approach.
- Any real contact info (email, phone) and API keys are split into a gitignored config.local.toml, never committed - the public repo only ever contains safe-to-share fields.
- Before committing, always run git status and git check-ignore -v config.local.toml to confirm PII/secrets are excluded.
- For a minor's personal site especially, treat this splitting rule as non-negotiable - verify before every single commit, not just the first one.

## Key Lessons Learned

1. Static site does not mean boring - a Hugo + Tailwind themed portfolio looks as polished as a hand-coded app, with none of the hosting complexity.
2. Adding a second site to an existing server is easier than people think - nginx virtual hosting via server_name matching means a new domain just needs a new config file, new cert, new web root. The existing site keeps running untouched.
3. Themes with build pipelines need their reference implementation, not just the bare theme repo.
4. Node version compatibility is a real, undocumented gotcha - Hugo's PostCSS pipeline needs Node 22.15+, not just "any recent Node."
5. Permissions matter - never serve web content from /root; nginx runs as an unprivileged user and can't reach it.

6. Cloudflare Origin CA is underrated - simpler than Certbot when always proxied, with a much longer cert lifespan. It's per-zone, so a new domain needs its own new cert even on a server that already has one.
7. Front matter structure is theme-specific - don't assume plain Markdown works everywhere; getting field names wrong causes silent failures, not errors.
8. Curate your content, don't dump everything - a linked resume PDF is the safety net for full detail.
9. Real bugs make for a more credible story - troubleshooting issues live is more relatable and more useful to viewers than a flawless scripted walkthrough.

## Reference URLs

- CareerCanvas theme: https://github.com/felipecordero/careercanvas
- Reference implementation: https://github.com/felipecordero/felipecordero.github.io
- Hugo releases: https://github.com/gohugoio/hugo/releases
- Pexels API: https://www.pexels.com/api/
- Live example: https://raycaparros.com
- Second site built using this guide: https://charisserosecaparros.com
- This repo: https://github.com/arcy24/raycaparros-site

This guide accompanies the "Building My Career Portfolio From Scratch" video series.
