/* ==========================================================================
   The console in Portuguese.

   THE KEY IS THE ENGLISH STRING, so there is no English dictionary — it would
   be an identity map — and a string with no entry here falls back to English by
   itself rather than breaking a screen. That fallback is what makes a
   half-translated console work perfectly and look finished, which is why
   `tools/check-interface internal/console/ui` exists: it fails on a string with
   no translation AND on a translation nothing says any more, because a stale
   entry reads as current.

   IT IS THIS CONSOLE'S OWN AND IT IS NOT COPIED FROM ANYWHERE. `ui/`'s
   `i18n-pt.js` is the study interface's, kept syncable with a repository that
   no longer exists; sharing one dictionary between the two would make every
   string of the one read as a stale entry to the other, which is precisely
   what the checker reports.

   # WHAT IS TRANSLATED AND WHAT IS DELIBERATELY NOT

   A ROLE IS NOT. `owner`, `operator` and `read-only` are what `staff grant`
   takes on a command line and what an audit entry records. A screen calling
   one of them something else would be a second name for one thing, and the
   person reading it would type the translation.

   A PARAMETER'S NAME IS NOT, for the same reason: `billing.instalments` is what
   the audit says and what somebody would quote over the phone.

   WHAT IS: everything a person reads as prose. The console's whole defence is
   that it prints the argument for what it is about to do — a knob's reason, why
   a queue hides its reporter, what a listing is for — and an argument nobody
   reads in their own language is an argument nobody reads.

   # SENTENCES THE SERVER WROTE ARE HERE TOO

   They arrive in English on an answer, English is the key, so they translate
   like anything else. The checker cannot see them: they are written in Go, and
   no static scan reaches them. That is the known edge, and it is why the last
   step before pushing is somebody opening the console in both languages.
   ========================================================================== */

window.I18N = window.I18N || {};
window.I18N.pt = window.I18N.pt || {};
window.I18N.pt.ui = {
  /* ---------- the shell ---------- */
  'Console': 'Console',
  'Choose a language': 'Escolha um idioma',
  'Switch to the light theme': 'Mudar para o tema claro',
  'Switch to the dark theme': 'Mudar para o tema escuro',
  'Console sections': 'Seções do console',
  /* THE KEY CARRIES THE `<p>`, and that is the checker reading `<noscript>` as
     the markup it is rather than as text: its contents are not parsed as
     elements by the browser until scripting is off, so what is there is one
     string. Matching what the tool asks for is the point — a key that looks
     tidier and is never matched translates nothing. */
  '<p>The console needs JavaScript. Everything it does is a request that has to be signed for.</p>':
    '<p>O console precisa de JavaScript. Tudo o que ele faz é um pedido que alguém ' +
    'tem de assinar.</p>',

  /* ---------- the rail ----------
     THE GROUPS ARE THE THREE JOBS `PLAN.md` SAYS MUST NOT MIX, so the
     Portuguese has to keep them apart as cleanly as the English does. */
  'Measure': 'Medir',
  'Operate': 'Operar',
  'Govern': 'Governar',

  'Who is here': 'Quem está aqui',
  'Jobs': 'Rotinas',
  'The funnel': 'O funil',
  'Questions': 'Questões',
  'Cohorts': 'Coortes',
  'Where they are': 'De onde são',
  'Reported content': 'Conteúdo reportado',
  'Student record': 'Ficha do aluno',
  'Schools': 'Escolas',
  'What it costs': 'Quanto custa',
  'What it is set to': 'Como está configurado',
  'Personal data': 'Dados pessoais',
  'Who can open this': 'Quem pode abrir isto',
  'History': 'Histórico',

  /* ---------- the router ---------- */
  'No such screen': 'Tela inexistente',
  'Nothing is routed at this address.': 'Nenhuma tela responde neste endereço.',

  /* ---------- the door ---------- */
  'shut': 'fechado',
  'signed out': 'desconectado',
  'Not signed in': 'Não conectado',
  'The door is shut': 'A porta está fechada',
  'The console could not tell who you are.': 'O console não conseguiu identificar quem é você.',
  /* A KEY IS ONE STRING ON ONE LINE, however long, AND THE VALUE MAY BE
     CONCATENATED. That is not a style rule: an object key cannot be an
     expression, so `'half ' + 'half':` is a syntax error — and the failure is
     the worst shape there is. The whole file stops parsing, `window.I18N` is
     never set, every screen falls back to English, and nothing looks broken.
     `check-interface` passed it: the tool reads keys with a regular expression
     rather than a parser, so it validated a file no browser could load.
     `language_test.go` fails on it now. */
  'Sign in at a school’s address, then come back here. This console cannot sign anybody in yet: sign-in belongs to a school and this belongs to none of them.':
    'Entre pelo endereço de uma escola e volte aqui. Este console ainda não consegue conectar ' +
    'ninguém: entrar pertence a uma escola, e este console não pertence a nenhuma.',
  'A staff role and a second factor already shown are both needed. The API refuses without either, and this page is not what enforces it.':
    'São necessários um papel de equipe e um segundo fator já apresentado. A API recusa sem ' +
    'qualquer um dos dois, e não é esta página que garante isso.',

  /* ---------- the tab that is older than the build ---------- */
  'This console has been open since before the last update. Reload it when you are ready.':
    'Este console está aberto desde antes da última atualização. Recarregue quando puder.',
  'Reload': 'Recarregar',
};
