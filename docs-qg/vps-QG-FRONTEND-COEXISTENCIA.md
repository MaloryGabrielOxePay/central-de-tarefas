# NOTA — Frontend do QG roda DO FORK (sessão de frontend/white-label)

> Escrito 2026-07-18 pela sessão de customização frontend. Leia antes de mexer
> em paperclip.service ou reinstalar o pacote npm.

## O que está diferente do runbook original

- O serviço `paperclip` NÃO roda mais o npm-global. Drop-in
  `/etc/systemd/system/paperclip.service.d/20-fork.conf` aponta o ExecStart para
  `/root/paperclip-fork` (branch `malory/whitelabel-base`, espelho privado
  `MaloryGabrielOxePay/paperclip-whitelabel`) via tsx, com
  `PAPERCLIP_UI_DEV_MIDDLEWARE=false` (static-ui servindo `ui/dist` brandado).
- Backend/DB/config INTOCADOS: mesmo `/root/.paperclip/config.json`, mesmo
  Postgres, mesma versão de schema (fork pinado na MESMA tag `v2026.707.0` do
  npm-global). Companies/agents/secrets criados via CLI/API funcionam igual.
- `bash /root/brand/apply-branding.sh` (hack antigo) ficou OBSOLETO: patcha o
  ui-dist do npm-global, que não é mais servido. Não precisa rodar no update.

## Regras de coexistência

1. `npm i -g paperclipai@...` NÃO muda mais o que roda. Para atualizar a
   versão de verdade: rebase do fork na nova tag + rebuild (doc completo:
   `/root/paperclip-fork/deploy/QG-DEPLOY.md`).
2. Para voltar ao npm-global (rollback de 1 comando):
   `rm -f /etc/systemd/system/paperclip.service.d/20-fork.conf && systemctl daemon-reload && systemctl restart paperclip`
3. A sessão de frontend só toca: `/root/paperclip-fork` + esse drop-in.
   Nunca toca: `/root/.paperclip` (config/DB), `/root/.hermes`, Caddy, ufw.
4. Restarts do serviço pela sessão de frontend são raros (1 por deploy, ~10s).
   Se um comando `paperclipai`/API falhar em janela de deploy, repetir.
