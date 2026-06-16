# Conectar el VPS (Claude Code) a GitHub + Vercel

> Para el Claude Code en Hostinger. Proyecto: `crm-kanban` (sitio estático HTML/CSS/JS).
> Regla de oro: **el VPS solo necesita poder hacer `git push`.** Vercel observa GitHub y
> redespliega solo. Así NO hay que poner el token de Vercel en el servidor.

---

## Arquitectura propuesta

**Un proyecto = un repo = un proyecto de Vercel.** No mezclar todo en un repo.

| Proyecto | Repo GitHub | Proyecto Vercel | URL |
|---|---|---|---|
| CRM Kanban | `crm-kanban` (privado) | crm-kanban | `crm-kanban.vercel.app` (o subdominio propio) |
| Juegos (galaga, space-invaders) | `arcade` (después) | arcade | `arcade.vercel.app` con un `index.html` de menú |

**Por qué separado:** el CRM es profesional, los juegos son aparte; deploys y URLs no se pisan.

**Flujo de ramas (igual que LFA):** `main` = producción (auto-deploy). Cambios grandes → rama →
preview automático de Vercel → merge a `main`.

**Estructura del repo `crm-kanban` (estático):**
```
crm-kanban/
  index.html          ← Vercel lo sirve directo desde la raíz
  assets/  (css, js, img)
  .gitignore
  README.md
```

**Persistencia (a futuro):** un Kanban va a querer guardar tarjetas. Hoy probablemente usa
`localStorage`. Cuando quieras que persista de verdad y multi-dispositivo, lo natural es
**Supabase** (ya lo usas en LFA, free tier) en vez de inventar backend. Por ahora no hace falta.

---

## Paso 1 — Git + primer commit (en el VPS)

```bash
cd /root/workspace/crm-kanban

git init
git branch -M main

cat > .gitignore <<'EOF'
node_modules/
.env
.env.*
.DS_Store
.vercel
*.log
EOF

git add .
git commit -m "Initial commit: CRM Kanban"
```

## Paso 2 — Autenticar GitHub (la forma fácil, sin token manual)

Instala GitHub CLI si no está:
```bash
type gh >/dev/null 2>&1 || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list \
  && sudo apt update && sudo apt install gh -y)
```

Login con **device flow** (funciona en servidor sin navegador):
```bash
gh auth login
# Elegir:  GitHub.com  →  HTTPS  →  "Login with a web browser"
# gh imprime un código de 8 dígitos. Abre https://github.com/login/device
# en tu teléfono/laptop, pega el código, autoriza. Listo.
```
> Alternativa para automatización: crear un Personal Access Token (classic, scope `repo`)
> en github.com/settings/tokens y `echo "TOKEN" | gh auth login --with-token`.
> **No pegues ese token en el chat de Claude/Cowork — solo en el VPS.**

## Paso 3 — Crear el repo y subir (un solo comando)

```bash
gh repo create crm-kanban --private --source=. --remote=origin --push
```
Esto crea el repo privado en GitHub y hace el primer push de `main`.

## Paso 4 — Conectar Vercel (desde el dashboard, una vez)

En vercel.com (en tu navegador, no en el VPS):
1. **Add New → Project → Import Git Repository → `crm-kanban`.**
2. Framework Preset: **Other**. Build Command: vacío. Output Directory: vacío/raíz
   (porque `index.html` está en la raíz). Root Directory: `./`.
3. **Deploy** → queda en `crm-kanban.vercel.app`.
4. Desde ahora: cada `git push` a `main` → Vercel redespliega solo. Ramas → preview.

> No hace falta instalar Vercel CLI en el VPS. Si algún día lo quieres directo:
> `npm i -g vercel && vercel login && vercel --prod` (pero el camino GitHub→Vercel es mejor).

---

## Comandos del día a día (en el VPS, ya configurado)

```bash
cd /root/workspace/crm-kanban
git add -A
git commit -m "descripcion del cambio"
git push            # Vercel redespliega producción automáticamente
```

## Seguridad
- Tokens (GitHub/Vercel) viven **solo en el VPS**, nunca en el chat ni en URLs.
- Repo en **privado** salvo que quieras el código público.
