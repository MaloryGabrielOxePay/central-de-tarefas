# QG (Paperclip) × Hermes — Runbook de Instalação

_Gerado em 2026-07-15. VPS `vmi3311151` (89.117.76.183), Ubuntu 24.04.4._

## Estado: NÚCLEO PRONTO E VERIFICADO ✅ · EXPOSIÇÃO PENDENTE ⏸️

Paperclip (control-plane de agentes) instalado, integrado ao Hermes via adapter
`hermes_local`, rodando como serviço systemd em **loopback** (127.0.0.1:3100) com
PostgreSQL de sistema. Smoke test end-to-end passou. Exposição pública (Caddy +
login + branding) está pausada aguardando correção de DNS e a logo.

---

## 1. Arquitetura final

```
Navegador ──(pendente: Caddy HTTPS + login)── 127.0.0.1:3100  paperclip.service (root)
                                                     │
                                                     ├── PostgreSQL 16 (127.0.0.1:5432, db "paperclip")
                                                     └── adapter hermes_local
                                                            └── spawn `hermes -q -m openai-codex/gpt-5.5`
                                                                   └── /root/.hermes (config + auth.json)
```

- **Por que Postgres de sistema (não o embutido):** o Postgres embutido do Paperclip
  se recusa a rodar como root, e o Paperclip não expõe o `createPostgresUser`. Como o
  adapter precisa de root para ler `/root/.hermes` (700/600), optou-se por root +
  Postgres de sistema (recomendação da própria doc do Paperclip para produção).
- **Modelo explícito:** `openai-codex/gpt-5.5` (Hermes autentica via `/root/.hermes/auth.json`).

## 2. Comandos executados (mutações)

```bash
# Backup do Hermes (nada do Hermes foi alterado; só leitura + backup)
BK=/root/.hermes/backups/pre-paperclip-2026-07-15_133950   # config.yaml, .env, auth.json, units

# Paperclip (app Node, pinado)
npm i -g paperclipai@2026.707.0
paperclipai onboard --yes --bind loopback --data-dir /root/.paperclip

# PostgreSQL de sistema
apt-get install -y postgresql postgresql-contrib
sudo -u postgres psql -c "CREATE ROLE paperclip LOGIN PASSWORD '***';"
sudo -u postgres psql -c "CREATE DATABASE paperclip OWNER paperclip;"
sudo -u postgres psql -d paperclip -c "CREATE EXTENSION IF NOT EXISTS pgcrypto; CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
# config.json: database.mode=postgres + connectionString (root-only)

# Company + agente
paperclipai company create --payload-json '{"name":"Quartel General"}'
paperclipai agent create -C <company> --payload-json '{"name":"Hermes Engineer","role":"engineer","adapterType":"hermes_local","adapterConfig":{"model":"openai-codex/gpt-5.5","provider":"openai-codex","maxTurnsPerRun":6,"timeoutSec":600,"graceSec":10,"toolsets":"terminal,file,web","persistSession":true,"quiet":true}}'

# Serviço durável
install -m 644 paperclip.service /etc/systemd/system/paperclip.service
systemctl daemon-reload && systemctl enable --now paperclip
```

## 3. Arquivos criados/alterados

| Caminho | O quê |
|---|---|
| `/usr/local/bin/paperclipai`, `/usr/local/lib/node_modules/paperclipai` | app (npm global) |
| `/root/.paperclip/instances/default/config.json` | config do Paperclip (aponta p/ Postgres; **contém segredo**, root-only) |
| `/root/.paperclip/instances/default/.env`, `.../secrets/master.key` | JWT + chave de secrets |
| `/etc/systemd/system/paperclip.service` | serviço systemd (root, loopback) |
| `/var/lib/postgresql/16/main` | cluster PostgreSQL |
| `/root/paperclip_smoke.txt` | artefato do smoke test (`SMOKE_OK`) |
| `/root/.hermes/backups/pre-paperclip-2026-07-15_133950/` | backup do Hermes |
| **Hermes (`/usr/local/lib/hermes-agent`, `/root/.hermes`, units)** | **NÃO alterado** (só leitura) |
| **`/etc/caddy/Caddyfile`** | **NÃO alterado** (exposição pendente) |

## 4. Como reverter (rollback completo)

```bash
# 1) Serviço Paperclip
systemctl disable --now paperclip
rm -f /etc/systemd/system/paperclip.service && systemctl daemon-reload

# 2) App + estado
npm rm -g paperclipai
rm -rf /root/.paperclip /root/paperclip_smoke.txt

# 3) Banco (dropar só o do Paperclip)
sudo -u postgres psql -c "DROP DATABASE IF EXISTS paperclip;"
sudo -u postgres psql -c "DROP ROLE IF EXISTS paperclip;"
#   (ou remover o Postgres inteiro:)
# apt-get purge -y postgresql postgresql-contrib 'postgresql-16*' && rm -rf /var/lib/postgresql

# 4) Hermes: intacto. Restaurar do backup só se desejar:
# cp -a /root/.hermes/backups/pre-paperclip-2026-07-15_133950/* /root/.hermes/
```
> Reversão é limpa: o Hermes nunca foi modificado. Nada foi exposto à internet.

## 5. Operação do dia a dia

```bash
systemctl status paperclip            # estado do serviço
journalctl -u paperclip -f            # logs ao vivo (Task 5)
paperclipai health --json             # saúde da API
paperclipai agent list -C <company>   # agentes
paperclipai run get <runId> --json    # status de um job
paperclipai run log <runId>           # log de um job (spawn do Hermes)
```

## 6. Checklist de testes (todos ✅)

- [x] Paperclip sobe — `health=ok` em 127.0.0.1:3100
- [x] Hermes aparece como adapter/agent — `hermes_local` loaded; agente "Hermes Engineer"
- [x] `detect-model` → `openai-codex/gpt-5.5` (risco: "sem modelos" ✔)
- [x] `test-environment` acha Hermes v0.18.2 (risco: "env não injetada" ✔)
- [x] Job simples executa — run `9c3f8613` = **succeeded**, criou `/root/paperclip_smoke.txt` = `SMOKE_OK`
- [x] Modelo explícito (risco: "modelo padrão quebrado" ✔ — auto→gpt-5.5)
- [x] Anti-loop: `maxTurnsPerRun=6` + `maxConcurrentRuns=1` + heartbeat (risco: "loop" ✔)
- [x] Logs fáceis — `journalctl -u paperclip`
- [x] Sobrevive a reboot e ao cutover — estado persiste no Postgres

## 7. Pendências (fase de exposição)

- [ ] **DNS:** corrigir A record `qg.grupomalory.com` → **89.117.76.183** (está 87.117.76.183, typo)
- [ ] **Logo/cores** do Grupo Malory (enviar por SFTP/URL/colar SVG)
- [ ] `paperclipai allowed-hostname qg.grupomalory.com`
- [ ] Modo `authenticated` (login+senha real) + bootstrap do 1º admin
- [ ] Bloco Caddy `qg.grupomalory.com` → `reverse_proxy 127.0.0.1:3100` (HTTPS/ACME)
- [ ] Branding: nome "Quartel General" (feito) + cor/logo; wordmark do frontend é opcional (patch frágil)

## 8. Observações

- Company renomeada para **"Quartel General"** (prefixo de issues: `HER`).
- Ao fechar uma issue, o agente tomou 404 numa rota de status (cosmético; o trabalho executa). A investigar se incomodar.
- Sem swap no host (11 GiB RAM livres); ok por ora.

## 9. Exposição pública (go-live) — CONCLUÍDO ✅

- **URL:** https://qg.grupomalory.com (HTTPS/Let's Encrypt automático via Caddy → `127.0.0.1:3100`)
- **Acesso:** login nativo (modo `authenticated`) — ninguém entra sem autenticar. Signup fechado (`disableSignUp=true`).
- **Admin:** `malory@grupomalory.com` (instance admin + owner da company). **Troque a senha no 1º login.**

### Mudanças aplicadas
| Item | Detalhe |
|---|---|
| `config.json` → `server.deploymentMode` | `authenticated` (era `local_trusted`) |
| `config.json` → `auth` | `disableSignUp=true`, `publicBaseUrl=https://qg.grupomalory.com`, `baseUrlMode=explicit` |
| `config.json` → `server.allowedHostnames` | `["qg.grupomalory.com"]` |
| drop-in `paperclip.service.d/10-proxy.conf` | `TRUST_PROXY=loopback`, `PAPERCLIP_PUBLIC_URL=https://qg.grupomalory.com` |
| `/etc/caddy/Caddyfile` | bloco `qg.grupomalory.com` → `reverse_proxy 127.0.0.1:3100` (backup: `/etc/caddy/Caddyfile.bak.pre-qg.*`) |
| Postgres `instance_user_roles` | `+ malory (instance_admin)` |
| Postgres `company_memberships` | `+ malory (owner de Quartel General)` |
| Branding | company "Quartel General" + `brandColor=#2436A8` (logo/favicon pendente de upload) |

### Segurança verificada
- Mutação sem login → **403**; Host fora da allowlist → **403**; certificado Let's Encrypt válido; `local_implicit` desligado em `authenticated` (sem bypass via proxy).

### Reverter a exposição (voltar a loopback-only)
```bash
# 1) Caddy: remover o bloco qg (restaurar backup mais recente)
cp -a "$(ls -t /etc/caddy/Caddyfile.bak.pre-qg.* | head -1)" /etc/caddy/Caddyfile
systemctl reload caddy
# 2) (opcional) voltar Paperclip a local_trusted (loopback, sem login)
python3 - <<'PY'
import json;p="/root/.paperclip/instances/default/config.json";c=json.load(open(p))
c["server"]["deploymentMode"]="local_trusted"; json.dump(c,open(p,"w"),indent=2)
PY
rm -f /etc/systemd/system/paperclip.service.d/10-proxy.conf
systemctl daemon-reload && systemctl restart paperclip
```

### Gerenciar via CLI em modo authenticated
- Normal: use a Web UI (você é admin).
- CLI local: `paperclipai connect --persona board` → aprove no navegador logado → token salvo no contexto do CLI.
- Manutenção de emergência: reverter para `local_trusted` (root) dá acesso implícito ao CLI temporariamente.

## 10. Branding QG/Malory & idioma

**Aplicado:**
- Company "Quartel General": `brandColor=#2436A8` + logo `grupo-malory.png` (asset `f15b8539…`).
- Favicon + `<title>` + `site.webmanifest` (name "Quartel General" / short "QG") no `ui-dist`, a partir da logo redonda Malory.
- Fontes em `/root/brand/` (baixadas de grupomalory.com); backup do original em `/root/brand/ui-dist-backup/`.

⚠️ **Após CADA `npm i -g paperclipai@...`** o `ui-dist` é sobrescrito → rode:
```bash
bash /root/brand/apply-branding.sh
```
(logo/cor da company ficam no Postgres, não precisam re-aplicar.)

**Não alterado (de propósito):** o wordmark "Paperclip" dentro do app (213× no JS compilado, misturado a nomes de cookie/rota/classe — find/replace quebraria o app).

**Idioma pt-BR:** Paperclip **não tem i18n** (sem seletor, sem catálogos, strings fixas no bundle). Traduzir o bundle é inviável/frágil. **Recomendado:** tradução nativa do navegador (Chrome/Edge/Brave → ícone "traduzir" ou botão direito → "Traduzir para o português"). UI inteira em PT, por usuário, toggle PT⇄EN, zero manutenção, sobrevive a updates.

### Reverter branding
```bash
cp -a /root/brand/ui-dist-backup/* /usr/local/lib/node_modules/paperclipai/node_modules/@paperclipai/server/ui-dist/
# + PATCH /api/companies/<id>/branding {"logoAssetId":null,"brandColor":null}
```

> Dica: se o favicon/título antigos “grudarem”, é cache do navegador/Service Worker — faça hard-refresh (Ctrl+Shift+R) ou limpe os dados do site.
