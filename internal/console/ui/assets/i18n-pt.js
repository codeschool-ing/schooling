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

  /* ---------- what every screen says while it is fetching ---------- */
  'Reading…': 'Lendo…',

  /* ---------- Govern · Who can open this ---------- */
  'Everybody with a role on this platform, and everybody who has had one. A role opens nothing without a second factor, and neither says whether it has been used — which is the column an access review is actually for.':
    'Todo mundo com um papel nesta plataforma, e todo mundo que já teve um. Um papel não ' +
    'abre nada sem um segundo fator, e nenhum dos dois diz se foi usado — que é a coluna ' +
    'para a qual uma revisão de acesso realmente serve.',
  'Everybody with a role on this platform': 'Todo mundo com um papel nesta plataforma',

  'Who': 'Quem',
  'Role': 'Papel',
  'Can get in': 'Consegue entrar',
  'Since': 'Desde',
  'Let in by': 'Autorizado por',
  'Last opened this': 'Abriu isto pela última vez',

  /* A COUNT IS TWO WHOLE SENTENCES. Building a plural by adding a letter to a
     translated noun is how "1 trilhas" shipped — a count of one followed by a
     plural — and Portuguese does not even agree with English about where the
     word goes. */
  'one row': 'uma linha',
  '%d rows': '%d linhas',

  'left': 'saiu',
  'revoked': 'revogado',
  'yes': 'sim',
  'no second factor': 'sem segundo fator',
  'never': 'nunca',
  'granted and not used': 'concedido e não usado',
  'until %s': 'até %s',
  'nobody — the first owner': 'ninguém — o primeiro dono',

  'Reading this list': 'Lendo esta lista',
  'Why there is no form': 'Por que não há formulário',

  /* THE THREE SENTENCES THIS SCREEN GETS FROM THE SERVER. They are written in
     Go, so `check-interface` cannot enumerate them — it says so in its own
     header. They arrive in English, English is the key, and they are here
     because somebody read the screen in Portuguese and found them. */
  'A role is granted and revoked with `staff grant` and `staff revoke`, from a terminal where the database is reachable. It is not a form here because the first owner cannot be granted a role by a console that needs one to open — so that door has to exist anyway, and a second door onto the same table would be a second thing to keep audited and in agreement.':
    'Um papel é concedido e revogado com `staff grant` e `staff revoke`, de um terminal onde ' +
    'o banco de dados é alcançável. Não é um formulário aqui porque o primeiro dono não pode ' +
    'receber um papel de um console que precisa de um para abrir — então essa porta tem de ' +
    'existir de qualquer forma, e uma segunda porta para a mesma tabela seria mais um caminho ' +
    'a manter auditado e em acordo.',
  'Every row here is somebody who can open this console, or could. The column worth reading is the last one: a role granted a year ago and never used since is access nobody is missing, and it is the row an access review exists to find. Revoked rows stay so that somebody who left is distinguishable from somebody who was never here.':
    'Cada linha aqui é alguém que pode abrir este console, ou podia. A coluna que vale ler é ' +
    'a última: um papel concedido há um ano e nunca usado desde então é acesso que ninguém ' +
    'sente falta, e é a linha que uma revisão de acesso existe para encontrar. Linhas ' +
    'revogadas ficam para que quem saiu seja distinguível de quem nunca esteve aqui.',
  'Nobody has a role, which cannot be true — this page was opened by somebody who has one. Something is answering wrongly rather than there being nobody here.':
    'Ninguém tem um papel, o que não pode ser verdade — esta página foi aberta por alguém que ' +
    'tem um. Algo está respondendo errado, e não é que não haja ninguém aqui.',

  /* ---------- Govern · History ---------- */
  'Every administrative action, newest first, with the person who took it against it. Nothing here can be edited: the table refuses an update and a delete, and a correction is a new entry.':
    'Toda ação administrativa, mais recentes primeiro, com a pessoa que a tomou ao lado. ' +
    'Nada aqui pode ser editado: a tabela recusa alteração e exclusão, e uma correção é ' +
    'uma entrada nova.',

  'History': 'Histórico',
  'One person’s doing': 'O que uma pessoa fez',

  /* THE KIND IS THE SERVER'S WORD IN A HOLE. `account`, `school`, `job` are
     what the audit records and what somebody searches by, so they stay as they
     are — and Portuguese does not put its preposition where English does, which
     is why the sentence has a hole rather than two halves. */
  'Everything done to one %s': 'Tudo o que foi feito em %s',
  'entry %s': 'entrada %s',

  'Entries': 'Entradas',
  'Everything again': 'Tudo de novo',
  'Nothing has been recorded here yet.': 'Nada foi registrado aqui ainda.',
  'the history could not be read': 'não foi possível ler o histórico',

  'When': 'Quando',
  'Did what': 'Fez o quê',
  'To': 'Em',
  'Why': 'Por quê',
  'School': 'Escola',
  'Request': 'Requisição',
  'system': 'sistema',
  'the platform, not a school': 'a plataforma, não uma escola',
  'an unknown moment': 'um momento desconhecido',

  /* FOUR WHOLE SENTENCES FOR ONE COUNT, because "so far" moves: English puts
     it after the noun and Portuguese before it, so a translation assembled from
     fragments cannot say it at all. */
  'one entry': 'uma entrada',
  '%d entries': '%d entradas',
  'one entry so far': 'uma entrada até agora',
  '%d entries so far': 'até agora, %d entradas',
  'Show more': 'Mostrar mais',

  'No such entry': 'Entrada inexistente',
  'Nothing is recorded under that number. History does not lose entries, so the number is wrong.':
    'Nada está registrado sob esse número. O histórico não perde entradas, então o número ' +
    'é que está errado.',
  'Back to the history': 'Voltar ao histórico',

  'What happened': 'O que aconteceu',
  'What the value was': 'Qual era o valor',
  'before': 'antes',
  'after': 'depois',
  'Before': 'Antes',
  'After': 'Depois',
  'A thing that did not exist yet has no before, and one that does not exist any more has no after. Not every action is a change of state, so an empty side is what was recorded rather than what happened.':
    'Uma coisa que ainda não existia não tem antes, e uma que não existe mais não tem ' +
    'depois. Nem toda ação é uma mudança de estado, então um lado vazio é o que foi ' +
    'registrado e não o que aconteceu.',
  'Nothing was recorded on this side.': 'Nada foi registrado deste lado.',

  /* ---------- Govern · Personal data ---------- */
  'What is held about one person, handed to them, or removed. Both of the last two are recorded with your name against them — an export is a read that leaves this system, and the record of who took it has to already exist by the time anybody asks.':
    'O que é guardado sobre uma pessoa, entregue a ela, ou removido. Os dois últimos são ' +
    'registrados com o seu nome — uma exportação é uma leitura que sai deste sistema, e o ' +
    'registro de quem a levou tem de já existir quando alguém perguntar.',

  'Find somebody': 'Encontrar alguém',
  'exact address': 'endereço exato',
  'The whole address': 'O endereço inteiro',
  'Look up': 'Procurar',
  'One person, or none.': 'Uma pessoa, ou nenhuma.',
  'No account at that address.': 'Nenhuma conta nesse endereço.',

  'Or look for somebody': 'Ou busque alguém',
  'a page at a time': 'uma página por vez',
  'Part of an address or a name': 'Parte de um endereço ou de um nome',
  'Look': 'Buscar',
  'Looking…': 'Buscando…',
  'silva, or @gmail.com, or nothing': 'silva, ou @gmail.com, ou nada',
  'Anything in an address or a name — a fragment is enough, and nothing at all lists everybody, newest first. Every page is recorded with your name, what you searched for and how many came back.':
    'Qualquer coisa em um endereço ou nome — um fragmento basta, e nada lista todo mundo, ' +
    'mais recentes primeiro. Cada página é registrada com o seu nome, o que você buscou e ' +
    'quantos voltaram.',
  'Nobody matches that.': 'Ninguém corresponde a isso.',
  'Signed up': 'Cadastrou-se',
  'synthetic': 'sintético',

  /* FOUR SENTENCES FOR ONE COUNT. See `showingPeople`. */
  'one person': 'uma pessoa',
  '%d people': '%d pessoas',
  'one person so far': 'uma pessoa até agora',
  '%d people so far': 'até agora, %d pessoas',

  /* AND FOUR FOR HOW MUCH IS HELD, which used to be a number, a space, the
     English word and an `s`. Portuguese does not build a plural that way, and
     it does not put "across" between two numbers at all. */
  'one row in one table': 'uma linha em uma tabela',
  'one row across %t tables': 'uma linha, distribuída em %t tabelas',
  '%r rows in one table': '%r linhas em uma tabela',
  '%r rows across %t tables': '%r linhas em %t tabelas',

  'Arrived %s': 'Chegou em %s',
  'Table': 'Tabela',
  'Rows': 'Linhas',
  'Nothing is held about them beyond the account itself.':
    'Nada é guardado sobre a pessoa além da própria conta.',
  'Found them, but could not count what is held.':
    'Encontrei a pessoa, mas não consegui contar o que é guardado.',

  'Export everything': 'Exportar tudo',
  'Recorded, with your name against it.': 'Registrado, com o seu nome.',
  'Their record': 'A ficha dela',

  'Erase them': 'Apagar a pessoa',
  'cannot be undone': 'não pode ser desfeito',
  'It severs the person and leaves the statistics. The entry in the audit says who did it and how much went, and does not name them.':
    'Isso desliga a pessoa e mantém as estatísticas. A entrada no histórico diz quem fez e ' +
    'quanto foi, e não a nomeia.',
  'Type their address to confirm': 'Digite o endereço dela para confirmar',
  'type %s to confirm': 'digite %s para confirmar',
  'Erase': 'Apagar',
  'Erased': 'Apagada',
  'The entry in the audit says who did it and how much went. It does not name them: an append-only table that recorded the address would be the last surviving copy of somebody who asked to be forgotten.':
    'A entrada no histórico diz quem fez e quanto foi. Ela não nomeia a pessoa: uma tabela ' +
    'que só cresce e que registrasse o endereço seria a última cópia sobrevivente de quem ' +
    'pediu para ser esquecido.',

  /* ---------- sentences the SERVER sends to these two screens ----------
     Written in Go, so `check-interface` cannot enumerate them; they are here
     because somebody opened the screens in Portuguese and read them. */
  'every action, every school': 'toda ação, todas as escolas',
  'one actor, every school': 'um autor, todas as escolas',
  'one %s, every school': 'um %s, todas as escolas',

  'This list answers a question somebody outside asked: they wrote in, and the address on the message is not the one they signed up with, or they signed their name and nothing else. It shows what identifies a person and not what is held about them — that is their record, one at a time, and the whole of it is the export, which is recorded against your name. Every page of this is recorded too, with what you searched for and how many came back.':
    'Esta lista responde a uma pergunta que alguém de fora fez: a pessoa escreveu, e o ' +
    'endereço da mensagem não é o do cadastro, ou ela assinou só o nome. Ela mostra o que ' +
    'identifica uma pessoa e não o que é guardado sobre ela — isso é a ficha dela, uma de ' +
    'cada vez, e o todo é a exportação, que fica registrada com o seu nome. Cada página ' +
    'desta lista também é registrada, com o que você buscou e quantos voltaram.',
  'Nobody here matches that. It is matched anywhere in the address or the name, so a fragment is enough — and nothing at all lists everybody, newest first.':
    'Ninguém aqui corresponde a isso. A busca casa em qualquer parte do endereço ou do ' +
    'nome, então um fragmento basta — e nada lista todo mundo, mais recentes primeiro.',

  /* ---------- the tab that is older than the build ---------- */
  'This console has been open since before the last update. Reload it when you are ready.':
    'Este console está aberto desde antes da última atualização. Recarregue quando puder.',
  'Reload': 'Recarregar',
};
