// Vercel Edge Middleware — gate de acesso server-side do HUB (Central de Tarefas).
// Catch-all (sem config.matcher) => intercepta TODAS as rotas. Fail-closed.
// O codigo vem da env var Vercel GATE_CODE (nunca em texto no repo publico).
// Sem GATE_CODE definida -> nega tudo (fail-closed). Sem cookie valido -> 401.

const CODE = (globalThis.process && globalThis.process.env && globalThis.process.env.GATE_CODE) || null;
const COOKIE = 'gate_ok';
const MAXAGE = 60 * 60 * 24 * 30; // 30 dias

export default function middleware(request) {
  const url = new URL(request.url);

  const cookies = request.headers.get('cookie') || '';
  const authed = cookies.split(';').some((c) => c.trim() === COOKIE + '=1');
  if (authed) {
    return new Response(null, { headers: { 'x-middleware-next': '1' } });
  }

  const attempt = url.searchParams.get('k');
  if (attempt !== null) {
    if (CODE && attempt === CODE) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: url.pathname || '/',
          'Set-Cookie': `${COOKIE}=1; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${MAXAGE}`,
          'Cache-Control': 'no-store',
        },
      });
    }
    return gate(true);
  }

  return gate(false);
}

function gate(err) {
  return new Response(gateHtml(err), {
    status: 401,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store, max-age=0',
      'X-Robots-Tag': 'noindex, nofollow, noarchive',
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
    },
  });
}

function gateHtml(err) {
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>HUB · Grupo Malory — Acesso restrito</title>
<style>
  :root{
    --bg:#0c0b12; --surface:#141320; --card:#1a1929; --border:#262438;
    --accent:#8b7cf7; --accent-soft:#1e1a3a; --text:#e4e2f0; --muted:#6b6780;
    --sans:'Inter',system-ui,-apple-system,Segoe UI,sans-serif;
    --display:'Space Grotesk',var(--sans);
  }
  *{box-sizing:border-box}
  body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px;
    background:radial-gradient(1200px 600px at 50% -10%, #1a1836, var(--bg));
    color:var(--text);font-family:var(--sans);line-height:1.6;-webkit-font-smoothing:antialiased}
  .card{width:min(92vw,420px);text-align:center}
  .lock{width:56px;height:56px;border:1px solid var(--border);border-radius:16px;background:var(--card);
    display:grid;place-items:center;color:var(--accent);margin:0 auto 22px}
  .lock svg{width:24px;height:24px}
  .brand{font-family:var(--display);font-weight:800;letter-spacing:2px;font-size:26px;margin:0 0 2px}
  .kicker{font-size:.72rem;text-transform:uppercase;letter-spacing:.18em;color:var(--muted);margin:0 0 22px}
  h1{font-family:var(--display);font-weight:700;font-size:1.25rem;margin:0 0 6px}
  .gp{color:var(--muted);font-size:.95rem;margin:0 0 22px}
  form{display:flex;gap:8px;justify-content:center;flex-wrap:wrap}
  input{font-size:1.4rem;letter-spacing:.5em;padding:.6em .7em;border:1px solid var(--border);
    border-radius:10px;background:var(--surface);color:var(--text);width:6.5ch;text-align:center;outline:none}
  input:focus{border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-soft)}
  button{font-family:var(--sans);font-weight:600;font-size:.95rem;cursor:pointer;padding:.75em 1.3em;
    border-radius:10px;border:none;background:var(--accent);color:#fff}
  button:hover{opacity:.9}
  .err{color:#f87171;font-size:.85rem;margin-top:14px;min-height:1.3em;${err ? '' : 'opacity:0;'}}
  .foot{font-size:.75rem;color:var(--muted);margin-top:30px;line-height:1.5}
</style>
</head>
<body>
  <div class="card">
    <div class="lock" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="10.5" width="16" height="9.5" rx="2"/><path d="M8 10.5V7a4 4 0 0 1 8 0v3.5"/></svg></div>
    <p class="brand">HUB</p>
    <p class="kicker">Grupo Malory · Central de Tarefas</p>
    <h1>Acesso restrito</h1>
    <p class="gp">Informe o código de 4 dígitos para acessar.</p>
    <form method="GET" autocomplete="off">
      <input name="k" type="password" inputmode="numeric" pattern="[0-9]*" maxlength="4"
        aria-label="Código de acesso" placeholder="••••" autofocus>
      <button type="submit">Entrar</button>
    </form>
    <div class="err" role="alert">${err ? 'Código incorreto.' : ''}</div>
    <p class="foot">Página interna, não indexada. Acesso verificado no servidor.</p>
  </div>
</body>
</html>`;
}
