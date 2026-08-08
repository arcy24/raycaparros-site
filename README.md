# Ray Caparros — Career Portfolio

> Security Architect & Engineer bridging offensive and defensive cybersecurity — from SOC operations and zero-trust architecture to red teaming and AI-driven security automation.

[![Built with Hugo](https://img.shields.io/badge/Built%20with-Hugo-FF4088?logo=hugo)](https://gohugo.io/)
[![Theme: CareerCanvas](https://img.shields.io/badge/Theme-CareerCanvas-blue)](https://themes.gohugo.io/themes/careercanvas/)
[![Deployed on Cloudflare](https://img.shields.io/badge/Protected%20by-Cloudflare-F38020?logo=cloudflare)](https://www.cloudflare.com/)

**Live Site:** [https://raycaparros.com](https://raycaparros.com)

---

## About This Project

This is my personal career portfolio — built as a living, working alternative to a static PDF resume. It's built with Hugo and the CareerCanvas theme, self-hosted on my own Linux server, secured with Cloudflare, and designed to showcase real technical work rather than just describe it.

### What Makes This Special

- **Self-Hosted End-to-End:** Domain, server, DNS, SSL, and deployment all configured from scratch
- **Version Controlled:** Every change tracked in Git with meaningful commits
- **One-Command Deploy:** A single script builds and publishes the site to production
- **Dynamic Content:** Randomized hero backgrounds (Pexels API) and color palettes on every page load
- **Real SSL Security:** Full (Strict) encryption via Cloudflare Origin CA
- **Working Contact Form:** Formspree-powered, no backend required

---

## Features

- About & Quick Facts: Education, certifications, and career highlights at a glance
- Experience: Curated career history across SOC leadership, security engineering, and teaching
- Dynamic Hero Backgrounds: Pulled live from the Pexels API, randomized per visit
- Randomized Color Palettes: A fresh look on every page load
- Contact Form: Direct message delivery via Formspree
- Calendly Integration: Book a meeting directly from the site
- Dark Mode: Clean, modern, easy on the eyes
- Mobile Responsive: Looks good on any device

---

## Quick Start

### Prerequisites

- Hugo Extended v0.164.0+
- Node.js v22.15+ and npm (earlier Node versions will fail during the PostCSS build step)
- Git

### Installation

```bash
git clone git@github.com:arcy24/raycaparros-site.git
cd raycaparros-site
git submodule init
git submodule update --recursive
npm install
export PATH="$PWD/node_modules/.bin:$PATH"
hugo server --config config.toml,config.local.toml --disableFastRender --bind 0.0.0.0
visit http://localhost:1313

Note: config.local.toml is gitignored and holds sensitive values (Pexels API key). You will need to create your own with:

```toml
[params]
  pexelsapikey = "your_key_here"
```

### Build for Production

```bash
npm run build:css
hugo --minify --config config.toml,config.local.toml
```

Output will be in the ./public/ directory.

---

## Project Structure

```
raycaparros-site/
├── config.toml              # Main Hugo configuration
├── config.local.toml        # Local secrets (gitignored)
├── content/en/               # About, Experience, Engineering, Contributions, Blog
├── static/images, files/     # Profile photo, resume PDF
├── themes/careercanvas/      # Theme (git submodule)
├── deploy.sh                  # One-command build + publish script
└── package.json                # Node/Tailwind build tooling
```

---

## Deployment

```bash
./deploy.sh
```

What deploy.sh does:
1. Builds Tailwind CSS
2. Builds the Hugo static site (using both config.toml and config.local.toml)
3. Syncs the built site to the live web root via rsync
4. Fixes file permissions for Nginx
5. Prompts to commit and push any uncommitted changes to GitHub

Infrastructure:
- Server: Self-managed Rocky Linux VPS
- Web Server: Nginx
- SSL: Cloudflare Origin CA certificate, Full (Strict) mode
- DNS & Protection: Cloudflare (proxied)

---

## Multi-Site Server Hosting

This server doesn't just host raycaparros.com — it's also configured to serve a **second, completely independent website** (charisserosecaparros.com) using Nginx **virtual hosting**. If you're following this repo as a learning reference, this section documents exactly how that was set up, since it's a common next step once your first site is live: adding a second site to the same server instead of paying for a whole new one.

### The Concept: Virtual Hosting

Nginx can serve multiple websites from a single server by reading the `server_name` directive in each config file and matching it against the `Host` header of incoming requests. Each site gets:
- its own DNS records (in its own Cloudflare zone)
- its own SSL certificate
- its own Nginx config file
- its own document root (web folder)

The underlying server, IP address, and Nginx installation are all shared.

### Step 1: Server-Level Prerequisites

These only need to be done once per server, regardless of how many sites you add later.

```bash
# Confirm OS
cat /etc/os-release

# Install Git
sudo dnf install -y git
git --version

# Install Nginx
sudo dnf install -y nginx
sudo systemctl enable --now nginx

# Open the firewall for web traffic (ports 80/443)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-services   # confirms http/https are now allowed

# Install Node.js 22 (REQUIRED — v20 fails on Hugo's PostCSS build step)
sudo dnf module install -y nodejs:22
node --version

# Confirm the server's public IP — you'll need this for DNS records
icurl -4 ifconfig.me
```

### Step 2: DNS (per new domain, in Cloudflare

For each additional domain you want to host on this server:

1. Add the domain to Cloudflare as its own separate zone (Add a Site) — Cloudflare treats every domain independently for DNS, SSL, and security, even when multiple domains point to the same server IP.
2. In that zone's DNS settings, add two A records, both proxied (orange cloud):
   - @ (root) → your server's public IP
   - www → same IP

### Step 3: Web Root + Placeholder Page
Give the new site its own folder to serve from, separate from raycaparros.com's:

```
sudo mkdir -p /var/www/charisserosecaparros.com/public
echo "<h1>charisserosecaparros.com — Coming Soon</h1>" | sudo tee /var/www/charisserosecaparros.com/public/index.html
sudo chown -R nginx:nginx /var/www/charisserosecaparros.com

```

### Step 4: SSL via Cloudflare Origin CA
Since this domain is fully proxied through Cloudflare, we use a Cloudflare Origin CA certificate instead of Certbot/Let's Encrypt — it lasts up to 15 years with no renewal cron job needed, as long as traffic stays proxied.

1. In the Cloudflare dashboard, go to the new domain's zone → SSL/TLS → Origin Server → Create Certificate (RSA 2048, 15-year validity).
2. Save the cert and key on the server:

```
sudo mkdir -p /etc/nginx/ssl

sudo tee /etc/nginx/ssl/charisserosecaparros.pem > /dev/null << 'EOF'
[paste certificate here]
EOF

sudo tee /etc/nginx/ssl/charisserosecaparros.key > /dev/null << 'EOF'
[paste private key here]
EOF

sudo chmod 600 /etc/nginx/ssl/charisserosecaparros.key

```

### Step 5: Nginx Virtual Host Config
This is the piece that actually tells Nginx "when someone requests charisserosecaparros.com, serve THIS folder" — separate from and without touching raycaparros.com's existing config.

```
sudo tee /etc/nginx/conf.d/charisserosecaparros.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name charisserosecaparros.com www.charisserosecaparros.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name charisserosecaparros.com www.charisserosecaparros.com;
    root /var/www/charisserosecaparros.com/public;
    index index.html;

    ssl_certificate     /etc/nginx/ssl/charisserosecaparros.pem;
    ssl_certificate_key /etc/nginx/ssl/charisserosecaparros.key;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

sudo nginx -t
sudo systemctl reload nginx

```

raycaparros.com's own config file (/etc/nginx/conf.d/raycaparros.conf) sits right alongside this one, completely untouched. 

### Step 6: Set Cloudflare SSL Mode
Back in the Cloudflare dashboard, for the new domain's zone: SSL/TLS → set mode to Full (Strict), now that a real certificate is installed on the origin server.

## Verify
Open the new domain in a browser — you should see the placeholder page with a valid padlock/HTTPS icon. That confirms the full domain → DNS → server → Nginx → SSL chain is working for the new site, independent of raycaparros.com.

| Site | Config File | Web Root | Cert |
|---|---|---|---|
| raycaparros.com | `/etc/nginx/conf.d/raycaparros.conf` | `/var/www/raycaparros.com/public` | `raycaparros.pem/.key` |
| charisserosecaparros.com | `/etc/nginx/conf.d/charisserosecaparros.conf` | `/var/www/charisserosecaparros.com/public` | `charisserosecaparros.pem/.key` |

### Built With AI-Assisted Development

This project was built end-to-end through an AI-assisted workflow using OpenWebUI and a conversational AI assistant — from initial concept through infrastructure setup, content generation, and debugging.

How the AI-assisted workflow helped:

- Planning & Architecture: Designed the full pipeline (domain, server, Hugo, deployment, SSL) before writing a single command
- Infrastructure Setup: Walked through server provisioning, DNS configuration, and SSL setup step-by-step, command by command
- Content Generation: Drafted About, Experience, and Quick Facts content using my real resume and career background as source material
- Real Debugging: Diagnosed and resolved actual production issues — a Node.js version incompatibility, a missing content file causing a silently empty page section, a deploy script not loading local secrets, and a contact form missing its API endpoint
- Documentation: Generated this README and the accompanying step-by-step tutorial guide

Every command was reviewed and run manually — nothing was auto-executed. This was a genuine back-and-forth: pasting terminal output, screenshots, and errors, and working through real problems together, not a one-shot generation.

---

## Technology Stack

- Static Site Generator: Hugo (Extended v0.164.0+)
- Theme: CareerCanvas
- CSS Framework: TailwindCSS (via theme)
- CSS Processing: PostCSS with Autoprefixer
- Dynamic Images: Pexels API
- Contact Form: Formspree
- Version Control: Git + GitHub
- Hosting: Self-managed VPS + Nginx
- DNS/SSL/Protection: Cloudflare
- Development Workflow: OpenWebUI + AI-assisted pair programming

---

## License

This project is open source and available for educational purposes — feel free to use it as a reference for building your own career portfolio.

---

## Resources & Links

- Live Site: https://raycaparros.com
- Hugo Documentation: https://gohugo.io/documentation/
- CareerCanvas Theme: https://github.com/felipecordero/careercanvas
- Formspree: https://formspree.io/
- Pexels API: https://www.pexels.com/api/

---

## Contact

- Website: https://raycaparros.com
- LinkedIn: https://www.linkedin.com/in/raycaparros
- GitHub Issues: https://github.com/arcy24/raycaparros-site/issues

---

**Built from scratch — domain, server, deployment, and all.**

*A live demonstration that a career portfolio can be more than a static PDF — and a real example of AI-assisted development done through genuine back-and-forth, not one-shot automation.*
