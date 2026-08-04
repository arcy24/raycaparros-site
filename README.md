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

## Built With AI-Assisted Development

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
