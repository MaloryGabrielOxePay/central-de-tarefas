<#
  publish-docs.ps1 — publica a documentacao do QG dentro do HUB.

  MODELO DE SEGURANCA (ler antes de mexer):
   - ALLOWLIST explicita. Nunca blocklist. Pasta que nao esta em $ALLOW nao sai do PC.
   - Trava de segredos: se qualquer arquivo casar com $SECRET_PAT, o script ABORTA
     sem escrever nada. Preferimos falhar a publicar credencial.
   - Escopo aprovado (2026-07-21): somente docs do QG (projects\QG\QG-DOCS).
     NUNCA incluir o vault Obsidian, em especial _Sensivel\ e _RAW\.
   - O conteudo publicado fica atras do gate do middleware.js (catch-all, fail-closed),
     mas isso e uma pagina na internet. So publique o que sobreviveria a um vazamento.

  Uso:  pwsh tools\publish-docs.ps1
#>

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$OutDir   = Join-Path $RepoRoot 'docs-qg'

# ── ALLOWLIST ────────────────────────────────────────────────────────────────
$ALLOW = @(
  @{ Nome = 'QG-DOCS';     Origem = 'C:\Users\artau\projects\QG\QG-DOCS';     Prefixo = '' }
  @{ Nome = 'QG-DOCS/vps'; Origem = 'C:\Users\artau\projects\QG\QG-DOCS\vps'; Prefixo = 'vps-' }
)

# ── TRAVA DE SEGREDOS ────────────────────────────────────────────────────────
$SECRET_PAT = 'sb_secret_|sbp_|eyJhbGciOi|ghp_|github_pat_|-----BEGIN|BEGIN OPENSSH|' +
              'password\s*[:=]\s*\S|senha\s*[:=]\s*\S|API_TOKEN\s*[:=]\s*\S|' +
              'Bearer\s+[A-Za-z0-9\-_\.]{20,}|GATE_CODE\s*[:=]\s*\d|SUPABASE_ACCESS_TOKEN\s*[:=]\s*\S'

Write-Host "== Coletando (allowlist) ==" -ForegroundColor Cyan
$arquivos = @()
foreach ($src in $ALLOW) {
  if (-not (Test-Path $src.Origem)) { throw "Origem da allowlist nao existe: $($src.Origem)" }
  $raiz = (Resolve-Path $src.Origem).Path
  Get-ChildItem $raiz -File -Filter *.md | ForEach-Object {
    # trava anti-escape: o arquivo resolvido tem que estar sob a raiz permitida
    if (-not $_.FullName.StartsWith($raiz, [StringComparison]::OrdinalIgnoreCase)) {
      throw "BLOQUEADO: caminho fora da allowlist -> $($_.FullName)"
    }
    $arquivos += [pscustomobject]@{
      Origem  = $_.FullName
      Destino = ($src.Prefixo + $_.Name)
      Grupo   = $src.Nome
      Bytes   = $_.Length
      Alterado= $_.LastWriteTime.ToString('yyyy-MM-dd')
    }
  }
}
Write-Host ("   {0} arquivos" -f $arquivos.Count)

Write-Host "== Varredura de segredos ==" -ForegroundColor Cyan
$achados = @()
foreach ($a in $arquivos) {
  $h = Select-String -Path $a.Origem -Pattern $SECRET_PAT -AllMatches -ErrorAction SilentlyContinue
  if ($h) { $achados += ("{0}:{1}" -f $a.Destino, ($h | Select-Object -First 1).LineNumber) }
}
if ($achados.Count -gt 0) {
  Write-Host "ABORTADO. Possivel segredo em:" -ForegroundColor Red
  $achados | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
  throw "Publicacao abortada pela trava de segredos. Nada foi escrito."
}
Write-Host "   limpo" -ForegroundColor Green

Write-Host "== Escrevendo docs-qg/ ==" -ForegroundColor Cyan
if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Force $OutDir | Out-Null

$manifesto = @()
foreach ($a in $arquivos) {
  Copy-Item $a.Origem (Join-Path $OutDir $a.Destino) -Force
  $texto = Get-Content $a.Origem -Raw -Encoding UTF8
  # titulo = primeiro H1, senao o nome do arquivo
  $titulo = ($texto -split "`n" | Where-Object { $_ -match '^\s*#\s+\S' } | Select-Object -First 1)
  if ($titulo) { $titulo = ($titulo -replace '^\s*#\s+', '').Trim() } else { $titulo = $a.Destino -replace '\.md$','' }
  $manifesto += [ordered]@{
    arquivo  = $a.Destino
    titulo   = $titulo
    grupo    = $a.Grupo
    bytes    = $a.Bytes
    alterado = $a.Alterado
  }
}

$idx = [ordered]@{
  gerado = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  escopo = 'Somente docs do QG (QG-DOCS). Vault Obsidian NAO incluido.'
  docs   = $manifesto
}
$json = $idx | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText((Join-Path $OutDir 'index.json'), $json, (New-Object Text.UTF8Encoding $false))

Write-Host ("   {0} docs + index.json" -f $manifesto.Count) -ForegroundColor Green
Write-Host ""
Write-Host "Pronto. Publicar:  git add docs-qg && git commit && git push origin main" -ForegroundColor Yellow
