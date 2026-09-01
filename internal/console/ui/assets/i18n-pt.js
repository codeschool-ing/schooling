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

  /* `History` is in the rail block above — it is a section name AND this
     screen's heading, which is one string and therefore one entry. */
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

  /* ---------- Operate · What it is set to ---------- */
  'Numbers the whole platform behaves by, changed here instead of by a deployment. Every change is recorded with your name, what was there and what replaced it — and each one asks you why.':
    'Números pelos quais a plataforma inteira se comporta, alterados aqui em vez de por um ' +
    'deploy. Cada mudança é registrada com o seu nome, o que estava lá e o que substituiu — ' +
    'e cada uma pergunta por quê.',
  'This list is closed. A parameter exists because some part of the system declared it — with what it counts in, the range it may move inside, the value the code ships with, and the argument for it being settable at all. There is no way to add one from here, and that is deliberate: a value with a right answer belongs in code, where a test holds it.':
    'Esta lista é fechada. Um parâmetro existe porque alguma parte do sistema o declarou — ' +
    'com a unidade em que conta, a faixa dentro da qual pode se mover, o valor com que o ' +
    'código sai, e o argumento para ele ser ajustável. Não há como acrescentar um daqui, e ' +
    'isso é deliberado: um valor que tem resposta certa pertence ao código, onde um teste o ' +
    'segura.',

  /* THE UNIT NAMES, which label the field. `count` becomes "How many" in
     English because that is what the field asks; Portuguese asks it the same
     way and the word is not a translation of "count". */
  'How many': 'Quantos',
  'Per cent': 'Por cento',
  'Days': 'Dias',
  'Hours': 'Horas',
  'Minutes': 'Minutos',
  'Seconds': 'Segundos',
  'Bytes': 'Bytes',
  'Value': 'Valor',

  'in a few words': 'em poucas palavras',
  'Save': 'Salvar',
  'Saving…': 'Salvando…',
  'A read-only role may look at this and not set it.':
    'Um papel somente-leitura pode olhar isto e não ajustar.',
  'That asks for an operator.': 'Isso pede um operador.',

  /* WHAT THE STATE LINE SAYS, in four cases rather than one sentence glued
     together from six pieces. The date is optional and the last clause is
     conditional, so the cases are enumerated: it is the only shape in which
     somebody translating can put "em <data>" where their language puts it. */
  'Set to %v. The code ships with %f.': 'Ajustado para %v. O código sai com %f.',
  'Set to %v on %d. The code ships with %f.': 'Ajustado para %v em %d. O código sai com %f.',
  'Somebody set it back to what it was, which is a decision and not an absence.':
    'Alguém o colocou de volta no que era, o que é uma decisão e não uma ausência.',
  'Nobody has changed this. It is on %s, which is what the code ships with — and what it falls back to if these rows are ever unreadable.':
    'Ninguém mudou isto. Está em %s, que é o valor com que o código sai — e para o qual ele ' +
    'volta se estas linhas alguma vez ficarem ilegíveis.',

  'A whole number. This one is counted in %s.': 'Um número inteiro. Este é contado em %s.',
  'This one takes %a to %b. That range is part of what declares it and cannot be moved from here — it is where the mistake of a digit too many is caught.':
    'Este aceita de %a a %b. Essa faixa faz parte do que o declara e não pode ser movida ' +
    'daqui — é onde o erro de um dígito a mais é pego.',
  'Say why in a few words. A parameter is replaced rather than appended, so this log is the whole history of what the platform was set to.':
    'Diga por quê em poucas palavras. Um parâmetro é substituído e não acrescentado, então ' +
    'este registro é toda a história de como a plataforma esteve ajustada.',
  'Saved. Every part of the platform that reads this is on the new number within fifteen seconds — the servers keep a short snapshot rather than asking the database on every request.':
    'Salvo. Toda parte da plataforma que lê isto está no número novo em quinze segundos — os ' +
    'servidores mantêm um retrato curto em vez de perguntar ao banco a cada requisição.',


  /* ---------- the ELEVEN ARGUMENTS, which are the point of that screen ----------

     `writes.go` says a knob costs a declaration, bounds and a sentence arguing
     that the value has no right answer — and the screen prints that sentence
     above the field because it is the whole cost of the knob existing. Left in
     English on a Portuguese screen it is a paragraph nobody reads, which is the
     same as not having spent it.

     They are written in Go, beside the code that reads each parameter, so
     `check-interface` cannot enumerate them. These are here because somebody
     opened the screen and read all eleven. */
  'how many answers a question needs before this platform says anything about it. Thirty is what classical item analysis uses, which is a rule of thumb rather than a result — the real choice is between saying something early and risking noise, or saying nothing until certain, and a cohort of forty and a cohort of four thousand want opposite ends of it. Every rollup records the sample it was judged against, so moving this changes what is said next and nothing already said.':
    'quantas respostas uma questão precisa antes de esta plataforma dizer qualquer coisa sobre ela. Trinta é o que a análise clássica de itens usa, o que é uma regra de bolso e não um resultado — a escolha real é entre dizer algo cedo e arriscar ruído, ou não dizer nada até ter certeza, e uma turma de quarenta e uma de quatro mil querem pontas opostas disso. Cada consolidação registra a amostra contra a qual foi julgada, então mexer nisto muda o que será dito adiante e nada do que já foi dito.',
  'how far a card sale may be split. Twelve costs half a point more in fees than six and halves the instalment a buyer compares against other schools; one turns instalments off. No interest is passed on at any count.':
    'em quantas partes uma venda no cartão pode ser dividida. Doze custa meio ponto a mais em taxas do que seis e reduz à metade a parcela que o comprador compara com outras escolas; um desliga o parcelamento. Nenhum juro é repassado em qualquer quantidade.',
  'how long somebody has to change their mind. Art. 49 of the Código de Defesa do Consumidor gives seven days for a purchase made at a distance and that is a floor rather than an answer — `Least` is 7 so no console can narrow it, and how far above the minimum to go is a commercial position: a longer window is something a school competes on and it costs whatever the refunds cost. The terms of use print this number rather than spelling one out, so the promise and the behaviour cannot part.':
    'quanto tempo alguém tem para mudar de ideia. O art. 49 do Código de Defesa do Consumidor dá sete dias para uma compra feita a distância, e isso é um piso e não uma resposta — `Least` é 7, então nenhum console consegue estreitar, e quanto ir acima do mínimo é uma posição comercial: uma janela maior é algo em que uma escola compete, e custa o que os estornos custarem. Os termos de uso imprimem este número em vez de escrever um por extenso, então a promessa e o comportamento não podem se separar.',
  'the share of an exam a student has to get right. Seventy is a convention and not a measurement — no test can say a school is wrong to want seventy-five — so it is how strict this platform chooses to be. Every attempt records the mark it was judged by, so moving this changes what a NEW attempt has to reach and nothing about a certificate already earned.':
    'a fração de uma prova que o aluno tem de acertar. Setenta é uma convenção e não uma medição — nenhum teste pode dizer que uma escola está errada em querer setenta e cinco — então é o quanto esta plataforma escolhe ser rigorosa. Cada tentativa registra a nota pela qual foi julgada, então mexer nisto muda o que uma tentativa NOVA precisa alcançar e nada sobre um certificado já conquistado.',
  'how long a paper is when the pool is longer. A short paper is quicker to sit and easier to get lucky on; a long one measures better and is abandoned more. Where to sit between those is a judgement about how this platform wants to be examined, and a pool smaller than the number is still asked in full.':
    'quantas questões uma prova tem quando o banco é maior. Uma prova curta é mais rápida de fazer e mais fácil de acertar por sorte; uma longa mede melhor e é abandonada mais. Onde ficar entre as duas é um julgamento sobre como esta plataforma quer ser examinada, e um banco menor que o número continua sendo perguntado por inteiro.',
  'how many address changes an account may ask for in an hour. Each one posts a message from our domain to an address the asker chose, so this is the bound on the one abuse the feature opens — and three is a guess about how often a person mistypes, which a school with half its addresses typed on phones may read differently. Below one the feature is off, which is a decision to make by deleting it; above ten it stops bounding the abuse and starts describing it.':
    'quantas trocas de endereço uma conta pode pedir em uma hora. Cada uma envia uma mensagem do nosso domínio para um endereço escolhido por quem pediu, então este é o limite do único abuso que o recurso abre — e três é um chute sobre com que frequência uma pessoa erra ao digitar, o que uma escola com metade dos endereços digitados no celular pode ler de outro jeito. Abaixo de um o recurso está desligado, o que é uma decisão a tomar apagando-o; acima de dez ele deixa de limitar o abuso e passa a descrevê-lo.',
  'how long a confirmation link keeps working. Nothing measures where the right answer is between an inbox read after work and a message forwarded to somebody else — services that have thought about it land anywhere within a day of ours. The fence is the part that is not a preference: under an hour somebody who stepped away has to ask again, and over three days a link in a forwarded message is a standing key.':
    'por quanto tempo um link de confirmação continua funcionando. Nada mede onde está a resposta certa entre uma caixa de entrada lida depois do expediente e uma mensagem encaminhada para outra pessoa — serviços que pensaram sobre isso caem em qualquer ponto a um dia do nosso. A cerca é a parte que não é preferência: abaixo de uma hora quem se afastou tem de pedir de novo, e acima de três dias um link numa mensagem encaminhada é uma chave permanente.',
  'how recently somebody has to have been seen to count as here. Nothing measures where \"now\" ends — a deploy going wrong is watched at the short end and an evening\'s traffic at the long one — so this is what the platform means by now. It cannot go below twice the heartbeat, because a window narrower than the writing cadence reports people as gone between their own requests.':
    'há quanto tempo alguém precisa ter sido visto para contar como presente. Nada mede onde o \"agora\" termina — um deploy dando errado é acompanhado na ponta curta e o tráfego de uma noite na ponta longa — então isto é o que a plataforma quer dizer por agora. Não pode ficar abaixo do dobro do batimento, porque uma janela mais estreita que a cadência de escrita reporta pessoas como ausentes entre as próprias requisições.',
  'how long an operator may look at a student\'s screens before the viewing stops working (K-02). It may only be made SHORTER: thirty is the ceiling and nothing can raise it, because a knob that went up would be one somebody turns on the afternoon it is inconvenient. An organisation that wants ten minutes is tightening the rule rather than loosening it, and there is no argument for refusing them.':
    'por quanto tempo um operador pode olhar as telas de um aluno antes de a observação parar de funcionar (K-02). Só pode ser ENCURTADO: trinta é o teto e nada o levanta, porque um botão que subisse seria um que alguém gira na tarde em que ele incomoda. Uma organização que quer dez minutos está apertando a regra e não afrouxando, e não há argumento para recusar.',
  'how long an answer may take and still count as remembered rather than nearly forgotten. Above it the answer was right and slow, which SM-2 reads as a card due back sooner. Forty-five seconds is the same first guess as the boundary below it and wants fitting against the same history.':
    'quanto tempo uma resposta pode levar e ainda contar como lembrada em vez de quase esquecida. Acima disso a resposta foi certa e lenta, o que o SM-2 lê como um cartão que volta mais cedo. Quarenta e cinco segundos é o mesmo primeiro chute que o limite abaixo dele, e quer ser ajustado contra a mesma história.',
  'how fast an answer has to be to count as known without hesitation, which is the top SM-2 grade. Ten seconds is a first guess and this file has always said so — it is roughly right for a quiz and roughly wrong for a labelling question, which takes longer for reasons that have nothing to do with knowing the answer. Every review records the boundary it was judged by, so moving this changes what is scheduled next and nothing already scheduled.':
    'quão rápida uma resposta tem de ser para contar como sabida sem hesitação, que é a nota máxima do SM-2. Dez segundos é um primeiro chute e este arquivo sempre disse isso — é aproximadamente certo para um quiz e aproximadamente errado para uma questão de rotular, que demora mais por razões que nada têm a ver com saber a resposta. Cada revisão registra o limite pelo qual foi julgada, então mexer nisto muda o que será agendado adiante e nada do que já foi agendado.',

  /* ---------- Operate · Reported content ----------
     `Reported content` is in the rail block above: it is a section name AND
     this screen's heading, which is one string and therefore one entry. */
  'What students say is wrong with the material. It is the only channel by which a wrong answer key comes back from the person who found it — the check that runs on every pull request can tell that a key parses and not that it is the right one.':
    'O que os alunos dizem estar errado no material. É o único canal pelo qual um gabarito ' +
    'errado volta de quem o encontrou — a verificação que roda em cada pull request sabe ' +
    'dizer que um gabarito é bem formado, não que ele está certo.',
  'There are no schools on this platform yet, so there is no material to report.':
    'Ainda não há escolas nesta plataforma, então não há material a reportar.',
  'Which school': 'Qual escola',
  'Waiting': 'Aguardando',
  'Nobody has reported anything in this school. That is the state this screen is meant to be in.':
    'Ninguém reportou nada nesta escola. É o estado em que esta tela deve estar.',
  'They picked a reason and wrote nothing.': 'A pessoa escolheu um motivo e não escreveu nada.',
  'Settling…': 'Resolvendo…',

  /* THE REASONS AND THE VERDICTS, drawn through a variable — `txt(WHY[r.reason])`
     — so `check-interface` cannot see them, the same blindness the rail has.
     `language_test.go` reads the two maps and holds them instead. */
  'answer key': 'gabarito',
  'not true': 'não é verdade',
  'does not work': 'não funciona',
  'cannot follow it': 'não dá para acompanhar',
  'something else': 'outra coisa',
  'The material was changed': 'O material foi alterado',
  'Looked at it — nothing is wrong': 'Olhei — não há nada errado',
  'Real, and not being fixed now': 'Procede, e não será corrigido agora',

  /* HOW LONG SOMEBODY HAS WAITED, in five sentences. `hours + ' hours'` builds
     a plural by concatenation, which is the shape that shipped "1 trilhas". */
  'unknown': 'desconhecido',
  'just now': 'agora mesmo',
  'one hour': 'uma hora',
  '%d hours': '%d horas',
  'one day': 'um dia',
  '%d days': '%d dias',

  /* ---------- Operate · Schools ---------- */
  'One colour each. It is the only thing that differs between schools — one design system, one accent — so a student knows which school they are in without the product looking like two products. Every change is recorded with your name, what was there and what replaced it.':
    'Uma cor cada. É a única coisa que difere entre escolas — um sistema de design, um ' +
    'destaque — para que o aluno saiba em qual escola está sem o produto parecer dois ' +
    'produtos. Cada mudança é registrada com o seu nome, o que estava lá e o que substituiu.',
  'A colour is <strong>replaced</strong>: there is one, and nothing has to be explained about the old one a year later. What a subscription costs is not here — one subscription opens every school, so there is one price for each term and it is set under <strong>What it costs</strong>.':
    'Uma cor é <strong>substituída</strong>: existe uma, e nada precisa ser explicado sobre a ' +
    'antiga um ano depois. Quanto custa uma assinatura não está aqui — uma assinatura abre ' +
    'todas as escolas, então há um preço por prazo, definido em <strong>Quanto custa</strong>.',
  'There are no schools on this platform yet. A school is a row, a host and a colour, in that order.':
    'Ainda não há escolas nesta plataforma. Uma escola é uma linha, um endereço e uma cor, ' +
    'nessa ordem.',

  'Colour': 'Cor',
  'Suggested colours for %s': 'Cores sugeridas para %s',
  'A colour is six hex digits after a hash, like <code class="mono">#5b8cff</code>. Empty is a real answer too: the school then wears the palette&rsquo;s own blue.':
    'Uma cor são seis dígitos hexadecimais depois de uma cerquilha, como ' +
    '<code class="mono">#5b8cff</code>. Vazio também é uma resposta de verdade: a escola ' +
    'passa a usar o azul da própria paleta.',
  'Six hex digits after a hash, like #5b8cff. A shorthand or a name reaches the interface as no colour at all, and the school stays as it was with nothing to say why.':
    'Seis dígitos hexadecimais depois de uma cerquilha, como #5b8cff. Uma forma abreviada ou ' +
    'um nome chega à interface como cor nenhuma, e a escola fica como estava sem nada que ' +
    'diga por quê.',
  'Saved. Students see it on their next page — nothing is cached about a school&rsquo;s colour.':
    'Salvo. Os alunos veem na próxima página — nada da cor de uma escola fica em cache.',

  /* THE TWO THEME NAMES, drawn through a variable like the verdicts. */
  'dark': 'escuro',
  'light': 'claro',
  'This browser could not measure the %s theme.':
    'Este navegador não conseguiu medir o tema %s.',
  'nothing on this hue reaches 4.5:1 against every surface it lands on, so this theme would keep the palette&rsquo;s own blue and the school would look like two different schools in the two themes.':
    'nada nesta matiz alcança 4,5:1 contra toda superfície em que pousa, então este tema ' +
    'manteria o azul da própria paleta e a escola pareceria duas escolas diferentes nos dois ' +
    'temas.',
  'Moved from %c, which reads at %r:1 here and needs 4.5. Same hue, far enough to be read.':
    'Movida de %c, que lê a %r:1 aqui e precisa de 4,5. Mesma matiz, longe o bastante para ' +
    'ser lida.',
  'Used exactly as chosen.': 'Usada exatamente como escolhida.',
  'A finished course and an available one come out the same colour in this theme: nothing on this hue is both readable and quieter than the accent.':
    'Um curso concluído e um disponível saem da mesma cor neste tema: nada nesta matiz é ao ' +
    'mesmo tempo legível e mais discreto que o destaque.',

  /* ---------- Operate · What it costs ---------- */
  'One subscription opens every school, so there is one price for each term and not one per school. Every change is recorded with your name, what was there and what replaced it.':
    'Uma assinatura abre todas as escolas, então há um preço por prazo e não um por escola. ' +
    'Cada mudança é registrada com o seu nome, o que estava lá e o que substituiu.',
  'A price is <strong>appended</strong>, never edited — saving one writes a new row dated from today and the old one stays, because a March invoice has to stay explicable in November. Saving the same number again is not a mistake: it records that this is still what we ask, as of today.':
    'Um preço é <strong>acrescentado</strong>, nunca editado — salvar um escreve uma linha ' +
    'nova datada de hoje e a antiga fica, porque uma fatura de março tem de continuar ' +
    'explicável em novembro. Salvar o mesmo número de novo não é engano: registra que é ' +
    'isto que ainda pedimos, a partir de hoje.',

  /* THE THREE TERMS, drawn through a variable — `txt(term.name)` — like the
     verdicts and the theme names. `language_test.go` holds them. */
  'A year': 'Um ano',
  'Two years': 'Dois anos',
  'A month': 'Um mês',
  'The subscription as it has always been quoted. One charge or one card that renews at the end of it.':
    'A assinatura como sempre foi cotada. Uma cobrança, ou um cartão que renova ao fim dela.',
  'One charge for a 24-month term, renewed as a new sale — no gateway here bills a subscription every two years, so this is not a recurrence.':
    'Uma cobrança por um prazo de 24 meses, renovada como venda nova — nenhum gateway aqui ' +
    'cobra uma assinatura a cada dois anos, então isto não é recorrência.',
  'For subscribers paying from abroad, where a stored card renewing monthly is what people expect.':
    'Para assinantes pagando do exterior, onde um cartão guardado renovando todo mês é o que ' +
    'as pessoas esperam.',

  'one month': 'um mês',
  '%d months': '%d meses',
  'Price': 'Preço',
  'Currency': 'Moeda',
  'Save a new price': 'Salvar um preço novo',
  'A price is an amount above zero, like 490 or 490.00. A term with no offer has no price at all rather than a price of nothing.':
    'Um preço é um valor acima de zero, como 490 ou 490,00. Um prazo sem oferta não tem ' +
    'preço nenhum, e não um preço de nada.',
  'A currency is three letters, ISO 4217 — BRL, EUR, USD. It is what a browser needs to format the amount.':
    'Uma moeda são três letras, ISO 4217 — BRL, EUR, USD. É o que um navegador precisa para ' +
    'formatar o valor.',
  'Saved as a new price, from today. The one before it is still in the series below.':
    'Salvo como preço novo, a partir de hoje. O anterior continua na série abaixo.',
  'Nothing is priced for this term, so nobody can buy it.':
    'Nada está precificado para este prazo, então ninguém consegue comprá-lo.',
  'What this costs could not be read, so this screen cannot say whether it is priced.':
    'Não foi possível ler quanto isto custa, então esta tela não sabe dizer se está ' +
    'precificado.',
  '%m — in force since %s': '%m — em vigor desde %s',

  'What comes off for a Pix': 'O que sai no Pix',
  'every term': 'todos os prazos',
  'A Pix settles in seconds and costs this platform less to receive than a card does, and this is the share of that handed back. It applies to every term, which is why it is one figure here rather than one per block above.':
    'Um Pix compensa em segundos e custa menos a esta plataforma do que um cartão, e esta é ' +
    'a parte disso que volta para quem paga. Vale para todos os prazos, e é por isso que é ' +
    'um número só aqui em vez de um por bloco acima.',
  'Off': 'Desconto',
  'per cent': 'por cento',
  'Save a new rate': 'Salvar uma taxa nova',
  'Nothing comes off a Pix. It is charged at the price above.':
    'Nada sai no Pix. Ele é cobrado pelo preço acima.',
  'A rate is a number above zero, like 5 or 7.5. Nothing off is not a rate of nothing — it is no discount at all, which is a different thing and is not set from here.':
    'Uma taxa é um número acima de zero, como 5 ou 7,5. Nada de desconto não é uma taxa de ' +
    'zero — é desconto nenhum, que é outra coisa e não se define daqui.',
  'Saved as a new rate, from today. The one before it is still in the series below.':
    'Salva como taxa nova, a partir de hoje. A anterior continua na série abaixo.',
  'A Pix': 'Um Pix',
  '%p% off': '%p% de desconto',
  '%p% off — in force since %s': '%p% de desconto — em vigor desde %s',

  'Every price ever set': 'Todo preço já definido',
  'Everything ever set': 'Tudo o que já foi definido',
  'Nothing is priced yet. The invitation then says what a subscription opens without naming a figure.':
    'Nada está precificado ainda. O convite então diz o que uma assinatura abre sem citar ' +
    'um valor.',
  'in force since %s': 'em vigor desde %s',
  'from %s': 'de %s',

  'Where a student writes to use the seven days': 'Para onde o aluno escreve nos sete dias',
  'The terms of use give a student seven days from the purchase to give the subscription back, for the whole amount and with no reason — art. 49 of the Código de Defesa do Consumidor. The account screen names that deadline whatever happens here, and names an address only when there is one.':
    'Os termos de uso dão ao aluno sete dias a partir da compra para devolver a assinatura, ' +
    'pelo valor inteiro e sem motivo — art. 49 do Código de Defesa do Consumidor. A tela da ' +
    'conta informa esse prazo aconteça o que acontecer aqui, e informa um endereço só quando ' +
    'existe um.',
  'Address': 'Endereço',
  'the old inbox is closed': 'a caixa antiga foi fechada',
  'Save this address': 'Salvar este endereço',
  'An address, or nothing at all — but nothing is cleared by the deployment rather than from here, and this form only sets one.':
    'Um endereço, ou nada — mas nada se limpa pelo deploy e não daqui, e este formulário só ' +
    'define um.',
  'Say why in a few words. This is published to every student, and the log has to tell an address that moved because the person answering changed from one that moved because the last was a typo.':
    'Diga por quê em poucas palavras. Isto é publicado para todo aluno, e o registro tem de ' +
    'distinguir um endereço que mudou porque quem responde mudou de um que mudou porque o ' +
    'anterior era um erro de digitação.',
  'Saved. Every student inside their seven days is now told to write there.':
    'Salvo. Todo aluno dentro dos seus sete dias passa a ser orientado a escrever para lá.',
  'Students are told to write to %e.': 'Os alunos são orientados a escrever para %e.',
  'Students are told to write to %e, set here on %d.':
    'Os alunos são orientados a escrever para %e, definido aqui em %d.',
  'Students are told to write to %e, which comes from this deployment&rsquo;s own configuration and not from here. Saving an address below takes it over — after that this screen is what decides it.':
    'Os alunos são orientados a escrever para %e, que vem da configuração do próprio deploy ' +
    'e não daqui. Salvar um endereço abaixo assume o lugar — a partir daí é esta tela que ' +
    'decide.',
  'Nobody is told where to write. The account screen still names the deadline, because knowing the date is worth something on its own — but a student inside the seven days has no address to use them at.':
    'Ninguém é orientado sobre para onde escrever. A tela da conta ainda informa o prazo, ' +
    'porque saber a data já vale alguma coisa — mas um aluno dentro dos sete dias não tem ' +
    'endereço nenhum para usá-los.',


  /* THE TWENTY SUGGESTED COLOURS. The hex beside each is the identifier and is
     never translated; the name is what a person — and a screen reader — reads. */
  'Cobalt': 'Cobalto',
  'Sky': 'Céu',
  'Cyan': 'Ciano',
  'Teal': 'Azul-petróleo',
  'Spring': 'Verde-primavera',
  'Emerald': 'Esmeralda',
  'Grass': 'Verde-grama',
  'Lime': 'Lima',
  'Olive': 'Oliva',
  'Amber': 'Âmbar',
  'Tangerine': 'Tangerina',
  'Copper': 'Cobre',
  'Vermilion': 'Vermelhão',
  'Crimson': 'Carmesim',
  'Rose': 'Rosa',
  'Fuchsia': 'Fúcsia',
  'Violet': 'Violeta',
  'Indigo': 'Índigo',
  'Periwinkle': 'Pervinca',
  'Slate': 'Ardósia',


  /* ---------- Operate · Student record ----------

     The largest screen in this console, and the one where every kind of
     string it has appears at once: headings, table columns, tags, the
     placeholders in four forms that move money or time, and the sentences
     that correct an expectation — "this does NOT cut their access" is the
     one an operator would otherwise get wrong out loud. */
  '%a live of %b': '%a ativas de %b',
  'one live of %b': 'uma ativa de %b',
  '%m for %n months': '%m por %n meses',
  '%m for one month': '%m por um mês',
  '%s across %n paid purchases. Not the ledger: an instalment plan is one sale here and one row per collection there.':
    '%s em %n compras pagas. Não é o livro-caixa: um parcelamento é uma venda aqui e uma ' +
    'linha por cobrança lá.',
  '%s across one paid purchase. Not the ledger: an instalment plan is one sale here and one row per collection there.':
    '%s em uma compra paga. Não é o livro-caixa: um parcelamento é uma venda aqui e uma ' +
    'linha por cobrança lá.',
  '%s, against an earlier line': '%s, contra uma linha anterior',
  'A currency is three letters, ISO 4217 — BRL, EUR, USD.': 'Uma moeda são três letras, ISO 4217 — BRL, EUR, USD.',
  'A read-only role may read this and not change it.': 'Um papel somente-leitura pode ler isto e não alterar.',
  'Access to': 'Acesso até',
  'Adjust the ledger': 'Ajustar o livro-caixa',
  'Amount': 'Valor',
  'An amount, like 655,50. Type what the line says.': 'Um valor, como 655,50. Digite o que a linha diz.',
  'An amount, like 69 or 69,00. An adjustment of nothing is not a correction.': 'Um valor, como 69 ou 69,00. Um ajuste de nada não é correção.',
  'Asked and accepted.': 'Pedido e aceito.',
  'Asking the gateway…': 'Pedindo ao gateway…',
  'At the gateway': 'No gateway',
  'Between one day and a year. More than that is two grants, and the second entry in the history is the record that you meant it.':
    'Entre um dia e um ano. Mais que isso são duas concessões, e a segunda entrada no ' +
    'histórico é o registro de que você quis mesmo.',
  'Cancel': 'Cancelamento',
  'Cancel it': 'Cancelar',
  'Cancelled. What they paid for still stands to the date above.': 'Cancelado. O que a pessoa pagou continua valendo até a data acima.',
  'Card, %d×': 'Cartão, %d×',
  'Card, in one': 'Cartão, à vista',
  'Certificates': 'Certificados',
  'Change something': 'Alterar alguma coisa',
  'Charged to them': 'Cobrado da pessoa',
  'Code': 'Código',
  'Course': 'Curso',
  'Courses': 'Cursos',
  'Credited to them': 'Creditado à pessoa',
  'Direction': 'Direção',
  'Everything done to them': 'Tudo o que foi feito com a pessoa',
  'Exams': 'Provas',
  'For': 'Por',
  'From': 'De',
  'Give it': 'Conceder',
  'Give time': 'Conceder tempo',
  'Given, and recorded as a grant rather than a sale.': 'Concedido, e registrado como concessão e não como venda.',
  'How': 'Como',
  'Issued': 'Emitido',
  'Last seen': 'Visto por último',
  'Look somebody up': 'Procurar alguém',
  'No money has moved either way.': 'Nenhum dinheiro se moveu em nenhuma direção.',
  'No paper sat here.': 'Nenhuma prova feita aqui.',
  'No subscription — but they have tried to buy, below.': 'Sem assinatura — mas houve tentativa de compra, abaixo.',
  'No such person': 'Pessoa inexistente',
  'Nothing awarded here.': 'Nada concedido aqui.',
  'Nothing bought, and nothing attempted.': 'Nada comprado, e nada tentado.',
  'Nothing held for this school on its own — the subscription above covers every school.': 'Nada mantido só para esta escola — a assinatura acima cobre todas as escolas.',
  'Nothing is held under that id.': 'Nada é guardado sob esse id.',
  'Nothing started here.': 'Nada iniciado aqui.',
  'One line in the books for money that moved outside the gateway: a bank transfer, a write-off, a goodwill credit. It tells the gateway NOTHING — no money moves because of this, it records that money moved somewhere else.':
    'Uma linha no livro-caixa para dinheiro que se moveu fora do gateway: uma ' +
    'transferência, uma baixa, um crédito de cortesia. Não diz NADA ao gateway — nenhum ' +
    'dinheiro se move por causa disto, ele registra que o dinheiro se moveu em outro ' +
    'lugar.',
  'One person, or none. Searching is on Personal data.': 'Uma pessoa, ou nenhuma. A busca fica em Dados pessoais.',
  'One row per browser they have signed in on. The token is not here and never will be — this says how many and since when, not how to become them.':
    'Uma linha por navegador em que a pessoa entrou. O token não está aqui e nunca estará ' +
    '— isto diz quantos e desde quando, não como se tornar a pessoa.',
  'Opened': 'Aberta',
  'Opened in a new tab. It ends in half an hour, or when you press stop there.': 'Aberto em uma aba nova. Termina em meia hora, ou quando você apertar parar lá.',
  'Paper': 'Prova',
  'Purchases': 'Compras',
  'Recorded with your name. Read-only, ends in half an hour, and they are not told.':
    'Registrado com o seu nome. Somente leitura, termina em meia hora, e a pessoa não é ' +
    'avisada.',
  'Reference': 'Referência',
  'Result': 'Resultado',
  'Sat': 'Feita em',
  'Say why. It is written down, and a change nobody can account for is worse than one that did not happen.':
    'Diga por quê. Fica registrado, e uma mudança que ninguém consegue justificar é pior ' +
    'que uma que não aconteceu.',
  'Sections': 'Seções',
  'See what they see': 'Ver o que a pessoa vê',
  'Send it back': 'Devolver',
  'Send money back': 'Devolver dinheiro',
  'Sittings': 'Sessões',
  'Somebody else': 'Outra pessoa',
  'Started': 'Iniciada',
  'Starting…': 'Iniciando…',
  'Subscription': 'Assinatura',
  'Term': 'Prazo',
  'That is not what this purchase came to. Type the amount on the line — a record with several purchases has several buttons that look the same.':
    'Não é esse o total desta compra. Digite o valor que está na linha — uma ficha com ' +
    'várias compras tem vários botões parecidos.',
  'The books': 'O livro-caixa',
  'They have never bought anything, and never tried to.': 'A pessoa nunca comprou nada, e nunca tentou.',
  'They have never signed in.': 'A pessoa nunca entrou.',
  'They have no subscription to cancel.': 'A pessoa não tem assinatura para cancelar.',
  'They have no subscription to extend. Giving somebody a term is not this: a subscription has to say what it was sold at, and there is no honest answer for one nobody bought.':
    'A pessoa não tem assinatura para estender. Dar um prazo a alguém não é isto: uma ' +
    'assinatura tem de dizer por quanto foi vendida, e não há resposta honesta para uma ' +
    'que ninguém comprou.',
  'They have nothing at any school: no plan, no progress, no exam, no certificate.':
    'A pessoa não tem nada em escola nenhuma: sem plano, sem progresso, sem prova, sem ' +
    'certificado.',
  'This asks the gateway and writes nothing here. Their access closes when the gateway&rsquo;s event comes back, which is seconds later and not part of the request. It cannot be undone.':
    'Isto pede ao gateway e não escreve nada aqui. O acesso da pessoa fecha quando o ' +
    'evento do gateway volta, o que é segundos depois e não faz parte da requisição. Não ' +
    'pode ser desfeito.',
  'This deployment has no payment gateway configured, so nothing can be sent back from here.':
    'Este deploy não tem gateway de pagamento configurado, então nada pode ser devolvido ' +
    'daqui.',
  'This does NOT cut their access. Every purchase here is a term bought outright and the paid period is honoured to its end — what stops is the reminder that it is about to run out.':
    'Isto NÃO corta o acesso. Cada compra aqui é um prazo comprado por inteiro e o ' +
    'período pago é honrado até o fim — o que para é o aviso de que está acabando.',
  'Time nobody paid for — an outage, a fortnight lost to support. It is recorded as a grant and not as a sale, so it will not appear in the purchases above and no money is written anywhere.':
    'Tempo que ninguém pagou — uma indisponibilidade, uma quinzena perdida no suporte. É ' +
    'registrado como concessão e não como venda, então não aparece nas compras acima e ' +
    'nenhum dinheiro é escrito em lugar nenhum.',
  'Type the amount': 'Digite o valor',
  'What': 'O quê',
  'What one person has, at each school: their plan, how far they have got, what they sat and what they were awarded. Reading it is not an export and is not recorded — what it shows is somebody&rsquo;s standing rather than their work.':
    'O que uma pessoa tem, em cada escola: o plano, até onde chegou, o que fez e o que ' +
    'recebeu. Ler isto não é uma exportação e não é registrado — o que mostra é a ' +
    'situação de alguém, e não o trabalho dela.',
  'Write it': 'Escrever',
  'Written. It is in the books and nowhere else — the gateway was not told, and no money has moved because of it. It is in the table below.':
    'Escrito. Está no livro-caixa e em nenhum outro lugar — o gateway não foi avisado, e ' +
    'nenhum dinheiro se moveu por causa disso. Está na tabela abaixo.',
  'an unknown day': 'um dia desconhecido',
  'arrived %s': 'chegou em %s',
  'bank transfer, receipt 4471': 'transferência, recibo 4471',
  'does not renew by itself': 'não renova sozinha',
  'ended': 'encerrada',
  'every school': 'todas as escolas',
  'expired': 'expirada',
  'failed': 'reprovado',
  'invoice': 'cobrança',
  'live': 'ativa',
  'never sent': 'nunca enviada',
  'not finished': 'não concluída',
  'not marked': 'não corrigida',
  'not paid': 'não paga',
  'not recorded': 'não registrado',
  'not said': 'não informado',
  'of %s': 'de %s',
  'open': 'em aberto',
  'opens every course': 'abre todos os cursos',
  'opens nothing': 'não abre nada',
  'paid through %s': 'pago até %s',
  'passed': 'aprovado',
  'the March outage cost them a fortnight': 'a queda de março custou uma quinzena',
  'the course was withdrawn, ticket 903': 'o curso foi retirado, chamado 903',
  'they asked to stop, ticket 812': 'a pessoa pediu para parar, chamado 812',
  'waiting': 'aguardando',

  /* ---------- Watch · Who is here ----------

     `Watch` IS THE RAIL'S GROUP AND THE SCREEN'S EYEBROW, and one entry serves
     both because it is one word saying one thing arriving from two files. The
     dictionary has no idea there are two and does not need one.

     THE TWO-NUMBER SENTENCES ARE FOUR ENTRIES AND NOT TWO WITH A PLURAL RULE.
     "1 minutos" is the defect this console has already shipped once, on a count
     of one — so a sentence whose number can be one is written twice, in full,
     and the screen picks between them. */
  'Watch': 'Acompanhar',
  'People signed in and seen a moment ago, by school. This is the one number in the console that comes from the sessions table rather than from the event stream — presence is the question where being overwritten is the point, because nobody asks who was online last March.':
    'Pessoas conectadas e vistas há pouco, por escola. Este é o único número do console que vem da tabela de sessões e não do fluxo de eventos — presença é a pergunta em que ser sobrescrito é justamente o ponto, porque ninguém pergunta quem estava online em março passado.',
  'On the platform': 'Na plataforma',
  'Seen in the last minute.': 'Vistas no último minuto.',
  'Seen in the last %w minutes.': 'Vistas nos últimos %w minutos.',
  'A session says it is still in use at most once a minute, so this number is accurate to that and no better — it moves in steps rather than smoothly, and that is the heartbeat rather than the platform.':
    'Uma sessão avisa que ainda está em uso no máximo uma vez por minuto, então este número é preciso até aí e não mais — ele anda aos saltos em vez de suavemente, e isso é o sinal de vida, não a plataforma.',
  'A session says it is still in use at most once every %c minutes, so this number is accurate to that and no better — it moves in steps rather than smoothly, and that is the heartbeat rather than the platform.':
    'Uma sessão avisa que ainda está em uso no máximo uma vez a cada %c minutos, então este número é preciso até aí e não mais — ele anda aos saltos em vez de suavemente, e isso é o sinal de vida, não a plataforma.',
  'By school': 'Por escola',
  'There are no schools on this platform yet.': 'Ainda não há escolas nesta plataforma.',
  'These do not add up to the number above, and should not: somebody studying in two schools is present in both and is <b>one person</b> on the platform.':
    'A soma destes não bate com o número acima, e não deve bater: quem estuda em duas escolas está presente nas duas e é <b>uma pessoa</b> na plataforma.',
  'What this does not count': 'O que isto não conta',
  'And it does not say <b>who</b>. This page refreshes on its own, so there is no moment where somebody asked for it and nothing to record a reason against — which is what a list of people has to carry. Looking somebody up is <b>Personal data</b>, where every page is recorded with what was searched for.':
    'E não diz <b>quem</b>. Esta página se atualiza sozinha, então não existe um momento em que alguém a pediu nem nada a que atribuir um motivo — que é o que uma lista de pessoas tem de carregar. Procurar alguém é <b>Dados pessoais</b>, onde cada página fica registrada com o que foi buscado.',
  'Read at %t · refreshing every %n s': 'Lido às %t · atualizando a cada %n s',

  /* ---------- Watch · Jobs ----------

     THE OUTCOME OF A RUN IS A WORD ON A ROW AND IS TRANSLATED; the JOB'S NAME
     is not, because it is what somebody types to start one and what the audit
     records. That is the line the roles and the parameter names are already on.

     `s` AND `m` STAY, being units rather than words. "and counting" is a
     sentence, and it goes after the number in English and before it elsewhere,
     so it is one key with a hole in it. */
  'What runs on a schedule, and how it went. This is the console reporting on itself: the question is not what students did, it is whether the work behind another screen actually happened last night.':
    'O que roda em horário marcado, e como foi. Aqui o console presta contas de si mesmo: a pergunta não é o que os alunos fizeram, é se o trabalho por trás de outra tela realmente aconteceu ontem à noite.',
  'This job has recorded no runs.': 'Esta rotina não registrou nenhuma execução.',
  'Run it now': 'Executar agora',
  'Asking…': 'Pedindo…',
  'Asked for.': 'Pedido.',
  'What starting one does': 'O que executar uma delas faz',
  'Why there is no button': 'Por que não há botão',
  'A read-only role may read this screen and not press anything. Starting a job withdraws questions from circulation when the analysis finds them broken, which is not a thing looking at a screen should do.':
    'Um papel somente-leitura pode ler esta tela e não apertar nada. Executar uma rotina tira questões de circulação quando a análise as encontra defeituosas, e isso não é coisa que olhar para uma tela deva fazer.',
  'A run still saying <b>running</b> after %d minutes is drawn as adrift. Nothing rewrites it: the row is what the job itself last said, and a job that was killed says nothing on the way out.':
    'Uma execução que ainda diz <b>em andamento</b> depois de %d minutos é desenhada como à deriva. Nada a reescreve: a linha é a última coisa que a própria rotina disse, e uma rotina que foi morta não diz nada ao sair.',
  'Finished': 'Concluída',
  'Failed': 'Falhou',
  'Running': 'Em andamento',
  'Adrift': 'À deriva',
  'never run': 'nunca executada',
  'started and never finished': 'começou e nunca terminou',
  'last run failed': 'a última execução falhou',
  'running now': 'executando agora',
  'last run %s': 'última execução %s',
  '%s and counting': '%s e contando',
  'at an unknown time': 'em um horário desconhecido',
  'within the hour': 'na última hora',
  'an hour ago': 'há uma hora',
  '%d hours ago': 'há %d horas',
  'yesterday': 'ontem',
  '%d days ago': 'há %d dias',

  /* ---------- Measure · the three controls all four screens share ----------

     THE POPULATIONS AND THE WINDOWS ARE ONE SET OF ENTRIES FOR FOUR SCREENS,
     which is not a saving — it is the point. `funnel.js`, `cohorts.js` and
     `countries.js` each hold their own `NAMES`, in English, and a reader moving
     between them has to see the same three words or conclude the three screens
     count different people. One entry per string is what guarantees that.

     NONE OF THEM IS VISIBLE TO `check-interface`: they are drawn through a
     variable. `language_test.go` reads the lists out of all four files. */
  'Real people': 'Pessoas reais',
  'The seeded population': 'A população semeada',
  'Everybody, real and seeded': 'Todo mundo, real e semeado',
  'Window': 'Janela',
  'People': 'Pessoas',
  'What to count': 'O que contar',
  'Since the beginning': 'Desde o início',
  'Last 30 days': 'Últimos 30 dias',
  'Last 90 days': 'Últimos 90 dias',
  'Last year': 'Último ano',

  /* ---------- Measure · The funnel ---------- */
  'Of the people who arrived at a school, how many reached each step. Every number is a count of people rather than of visits: somebody who arrived without an account and came back signed in is one person, which is the only reason the top and the bottom of this can be compared at all.':
    'Das pessoas que chegaram a uma escola, quantas alcançaram cada etapa. Todo número aqui é uma contagem de pessoas e não de visitas: quem chegou sem conta e voltou conectado é uma pessoa só, que é a única razão pela qual o topo e o fundo disto podem ser comparados.',
  'There are no schools on this platform yet, so there is nobody to have arrived at one.':
    'Ainda não há escolas nesta plataforma, então não há ninguém para ter chegado a uma.',
  'Nobody has reached any step of this, in this window, for these people. An empty funnel is a real answer and not a failure to read one.':
    'Ninguém alcançou nenhuma etapa disto, nesta janela, para estas pessoas. Um funil vazio é uma resposta de verdade e não uma falha em ler uma.',
  /* THE REASON A STEP IS NOT COUNTED IS THE SERVER'S SENTENCE and translates on
     its own; this is only what joins the two, which is punctuation that does not
     sit in the same place in every language. */
  'Not counted yet — %s': 'Ainda não contado — %s',

  /* THE LAST STEP BELONGS TO THE PLATFORM AND NOT TO THE SCHOOL, which this
     screen says twice on purpose: once on the row, where somebody scanning the
     chart will see it, and once underneath, where the reason fits. */
  'platform-wide': 'toda a plataforma',
  'The last step is not about this school. One subscription opens every school, so it counts the people who arrived here and went on to subscribe anywhere — which means two schools can each count the same person, and their last steps do not add up to the number of subscribers on the platform.':
    'A última etapa não é sobre esta escola. Uma assinatura abre todas as escolas, então ela conta as pessoas que chegaram aqui e passaram a assinar em qualquer lugar — o que significa que duas escolas podem contar a mesma pessoa, e a soma das últimas etapas delas não dá o número de assinantes da plataforma.',

  /* ---------- Measure · Questions ----------

     THE FIVE VERDICTS AND WHAT EACH MEANS are drawn through a variable and are
     `language_test.go`'s. Three of the five names are also the headings of the
     thresholds further down that screen, and they share one entry each on
     purpose: somebody matching a verdict to the rule that produced it should not
     have to notice that two translations mean the same thing. */
  'What the answers say about each question, worst first. Every number that is a judgement is followed by what it was judged against — the thresholds come from the code that applied them, so this screen and the job cannot drift apart.':
    'O que as respostas dizem sobre cada questão, pior primeiro. Todo número que é um julgamento vem seguido daquilo contra o que foi julgado — os limites vêm do código que os aplicou, então esta tela e a rotina não podem divergir.',
  'There are no schools on this platform yet, so there are no questions to have been answered.':
    'Ainda não há escolas nesta plataforma, então não há questões para terem sido respondidas.',
  /* `Which school` IS ALREADY UP IN `Personal data`'s SECTION, one entry for
     both screens. A second copy here would be legal JavaScript, silently keep
     the last, and make one of the two translations decide nothing — which is
     what `TestNoKeyIsWrittenTwice` exists to catch, and did. */
  'Real students only — see below.': 'Apenas alunos reais — veja abaixo.',
  'Nothing has been computed for this school': 'Nada foi calculado para esta escola',
  'The nightly analysis has never written a row here. That is not the same as every question being fine — it is nobody having looked. If this school has been answering questions for a while, the job is what to check.':
    'A análise noturna nunca escreveu uma linha aqui. Isso não é o mesmo que todas as questões estarem bem — é ninguém ter olhado. Se esta escola já responde questões há algum tempo, a rotina é o que verificar.',
  'Computed %s': 'Calculado em %s',
  'The analysis ran and found no question with any answers to it yet.':
    'A análise rodou e não encontrou nenhuma questão com respostas ainda.',
  'one question': 'uma questão',
  '%d questions': '%d questões',
  'Inverted': 'Invertida',
  'The students who did well on the paper got this right LESS often than the students who did badly. That is a wrong key, an ambiguous prompt, or a question asking something other than what it looks like.':
    'Os alunos que foram bem na prova acertaram esta MENOS vezes do que os alunos que foram mal. Isso é um gabarito errado, um enunciado ambíguo, ou uma questão que pergunta outra coisa que não o que parece.',
  'Weak': 'Fraca',
  'It barely separates students. Worth a look, and not evidence of anything broken.':
    'Ela mal separa os alunos. Vale uma olhada, e não é prova de nada quebrado.',
  'Too easy': 'Fácil demais',
  'Almost everybody gets it right, so it measures nothing. A content problem rather than a broken question.':
    'Quase todo mundo acerta, então ela não mede nada. Um problema de conteúdo, e não uma questão quebrada.',
  'Fine': 'Bem',
  'Doing its job.': 'Fazendo o seu trabalho.',
  'Not enough answers': 'Respostas insuficientes',
  'Nothing is being said about this one yet. It is the starting state of every question and it is not a criticism.':
    'Nada está sendo dito sobre esta ainda. É o estado inicial de toda questão e não é uma crítica.',
  'A scatter plot of the questions on this screen: how often each one is got right, across; how well each one separates students, up. The lines on it are the thresholds. The list below has every question and its numbers.':
    'Um gráfico de dispersão das questões desta tela: quantas vezes cada uma é acertada, na horizontal; o quanto cada uma separa os alunos, na vertical. As linhas nele são os limites. A lista abaixo tem cada questão e seus números.',
  'One question is not on the chart: too few people have answered it, and an index nobody has measured is not a zero to draw. It is in the list below, with the number of answers it still needs.':
    'Uma questão não está no gráfico: pouca gente respondeu a ela, e um índice que ninguém mediu não é um zero para desenhar. Ela está na lista abaixo, com quantas respostas ainda faltam.',
  '%d questions are not on the chart: too few people have answered them, and an index nobody has measured is not a zero to draw. They are in the list below, with the number of answers each still needs.':
    '%d questões não estão no gráfico: pouca gente respondeu a elas, e um índice que ninguém mediu não é um zero para desenhar. Elas estão na lista abaixo, com quantas respostas faltam para cada uma.',
  'Out of circulation': 'Fora de circulação',
  'Still being asked': 'Ainda sendo perguntada',
  'Answers': 'Respostas',
  'at or over %d, the minimum to say anything': 'em %d ou mais, o mínimo para dizer qualquer coisa',
  'under %d, the minimum to say anything': 'abaixo de %d, o mínimo para dizer qualquer coisa',
  'Got it right': 'Acertaram',
  '%s (%c of %a)': '%s (%c de %a)',
  'too easy at %e and up, very hard under %h — hard is not a fault':
    'fácil demais de %e para cima, muito difícil abaixo de %h — difícil não é defeito',
  'Discrimination': 'Discriminação',
  'inverted at %i and under, weak under %w':
    'invertida em %i ou menos, fraca abaixo de %w',
  'The two groups': 'Os dois grupos',
  '%s strong, %w weak': '%s fortes, %w fracos',
  'the top and bottom %p% by the REST of the paper, so a question is not part of its own ranking':
    'os %p% do topo e do fundo pelo RESTO da prova, para que uma questão não faça parte do próprio ranking',
  'Answered %a to %b': 'Respondida de %a a %b',
  'How this is decided': 'Como isto é decidido',
  'Minimum sample': 'Amostra mínima',
  '%d answers before anything is said. Classical item analysis’s number, and where the index stops being dominated by which particular people sat the paper.':
    '%d respostas antes de dizer qualquer coisa. É o número da análise clássica de itens, e onde o índice deixa de ser dominado por quais pessoas em particular fizeram a prova.',
  'Groups': 'Grupos',
  'The top and bottom %p% of attempts, ranked by the rest of the paper. Ranking by the WHOLE paper puts a question inside its own ranking, which hid an inverted key on every paper length this platform sets.':
    'Os %p% do topo e do fundo das tentativas, ordenados pelo resto da prova. Ordenar pela prova INTEIRA coloca uma questão dentro do próprio ranking, o que escondeu um gabarito invertido em todo tamanho de prova que esta plataforma monta.',
  'Discrimination at %s or under. The only verdict that is a defect, and the only one this system can find without a person.':
    'Discriminação em %s ou menos. O único veredito que é um defeito, e o único que este sistema consegue encontrar sem uma pessoa.',
  'Under %s. A note.': 'Abaixo de %s. Uma observação.',
  '%s or more get it right.': '%s ou mais acertam.',
  'Very hard': 'Muito difícil',
  'Under %s get it right. Reported and never condemned on its own — a question almost nobody answers may be an excellent one.':
    'Menos de %s acertam. Reportada e nunca condenada por si só — uma questão que quase ninguém responde pode ser excelente.',
  'Who is counted': 'Quem é contado',

  /* ---------- Measure · Cohorts ---------- */
  'People grouped by the month they signed up, followed forward. Each row is one intake and each column is a month of its life, so two intakes can be compared at the same age — which the funnel, being a single photograph of everybody at once, cannot do.':
    'Pessoas agrupadas pelo mês em que se inscreveram, acompanhadas adiante. Cada linha é uma entrada e cada coluna é um mês de vida dela, então duas entradas podem ser comparadas na mesma idade — o que o funil, sendo uma única fotografia de todo mundo de uma vez, não consegue fazer.',
  'There are no schools on this platform yet, so nobody has signed up to one.':
    'Ainda não há escolas nesta plataforma, então ninguém se inscreveu em nenhuma.',
  'What to follow': 'O que acompanhar',
  'Followed for': 'Acompanhado por',
  '6 months': '6 meses',
  '12 months': '12 meses',
  '24 months': '24 meses',
  'Nobody has signed up to this school yet, for these people. An empty table is a real answer and not a failure to read one.':
    'Ninguém se inscreveu nesta escola ainda, para estas pessoas. Uma tabela vazia é uma resposta de verdade e não uma falha em ler uma.',
  'Active means <strong>%s</strong> — the smallest signal that somebody actually studied that month. Every share is of the intake, including the first column: an intake where half never started is a different problem from one that starts well and leaks.':
    'Ativo significa <strong>%s</strong> — o menor sinal de que alguém de fato estudou naquele mês. Toda proporção é sobre a entrada, inclusive na primeira coluna: uma entrada em que metade nunca começou é um problema diferente de uma que começa bem e vaza.',
  /* THE SECOND BASIS IS BUILT NOW, so what this screen needs is not the old
     apology block but the words for the control and the column. `Counted from`
     is both the control's label and the block's heading — one string saying one
     thing in two places, which is what keeps them reading as the same idea. */
  'Counted from': 'Contado a partir de',
  'the month they signed up': 'do mês em que se inscreveram',
  'the month they started paying': 'do mês em que começaram a pagar',
  'Month they started paying': 'Mês em que começou a pagar',
  /* THE COLUMN IS `Month they signed up` AND NOT `Signed up`, and the reason is
     the dictionary rather than the screen: `Signed up` is already the student
     record's label for the DAY somebody registered, and one English string can
     only have one entry. Two screens meaning different things by the same words
     is how a translation ends up wrong on the screen that lost. */
  'Month they signed up': 'Mês da inscrição',
  'same month': 'mesmo mês',
  'not yet': 'ainda não',

  /* ---------- Measure · Where they are ----------

     THE COUNTRY NAMES ARE NOT HERE and never will be. `Intl.DisplayNames` has
     all 249 of them in both languages, in the browser, which is exactly why the
     answer comes back as ISO codes — see `countries.js`. What is here is the
     words around them. */
  'The people of one school, by the country each request came from. The country is worked out in this process from the address and the address is discarded, which is what the privacy policy promises and the reason there is no city here and never will be.':
    'As pessoas de uma escola, pelo país de onde veio cada requisição. O país é deduzido neste processo a partir do endereço e o endereço é descartado, que é o que a política de privacidade promete e a razão pela qual não há cidade aqui e nunca haverá.',
  'There are no schools on this platform yet, so there is nobody to be anywhere.':
    'Ainda não há escolas nesta plataforma, então não há ninguém para estar em lugar algum.',
  'Nobody has done anything at this school, in this window, for these people. An empty world is a real answer and not a failure to read one.':
    'Ninguém fez nada nesta escola, nesta janela, para estas pessoas. Um mundo vazio é uma resposta de verdade e não uma falha em ler uma.',
  'one person, in one country.': 'uma pessoa, em um país.',
  'one person, in %c countries.': 'uma pessoa, em %c países.',
  '%p people, in one country.': '%p pessoas, em um país.',
  '%p people, in %c countries.': '%p pessoas, em %c países.',
  'These add up to %s and there are %p people, because somebody who studied from two countries is honestly in both. The countries are shares of where the studying happened; the number above is how many people did it.':
    'Isto soma %s e há %p pessoas, porque quem estudou de dois países está honestamente nos dois. Os países são proporções de onde o estudo aconteceu; o número acima é quantas pessoas o fizeram.',
  'A world map with nothing shaded on it.': 'Um mapa-múndi sem nada sombreado nele.',
  'A world map. %s are shaded. The list below has every country and its count.':
    'Um mapa-múndi. %s estão sombreados. A lista abaixo tem cada país e sua contagem.',
  '%s and one more': '%s e mais um',
  '%s and %d more': '%s e mais %d',
  'The map shows only the people whose country is known. The rest are in the list below, under “Nobody knows where”.':
    'O mapa mostra apenas as pessoas cujo país é conhecido. As demais estão na lista abaixo, sob “Ninguém sabe onde”.',
  'Nobody knows where': 'Ninguém sabe onde',
  'No country could be worked out — a request from before there was a database to work it out with, or one through something that hides where it came from.':
    'Nenhum país pôde ser deduzido — uma requisição de antes de haver um banco de dados para deduzi-lo, ou uma passando por algo que esconde de onde veio.',

  /* ---------- sentences the SERVER sends to Watch and Measure ----------

     Written in Go, so `check-interface` cannot enumerate them and nothing but
     opening the screens finds them missing. They are here because somebody did.

     WHAT IS NOT HERE: `section.completed`, which arrives on the cohorts answer
     as the definition of "active". That is an event name — the thing the stream
     holds and the thing somebody would grep for — and it is on the same line as
     the roles and the parameter names. The sentence around it translates; it
     does not. */
  'People signed in, and only them: somebody reading a course without an account is not counted, because a visitor\'s heartbeat is hourly and answers a different question. Nor is an operator viewing a student\'s screens, nor a seeded student — who never signs in at all.':
    'Pessoas conectadas, e apenas elas: quem lê um curso sem conta não é contado, porque o ' +
    'sinal de vida de um visitante é de hora em hora e responde outra pergunta. Nem um ' +
    'operador vendo as telas de um aluno, nem um aluno semeado — que nunca se conecta.',

  'No job has recorded a run. Before the first night that is what this screen says — and it is also what it says if nothing is scheduled at all.':
    'Nenhuma rotina registrou uma execução. Antes da primeira noite é isso que esta tela ' +
    'diz — e é também o que ela diz se nada estiver agendado.',
  'Starting one asks for a run now instead of waiting for the next night. It is recorded with your name — the run\'s own row cannot say who asked, because the scheduler makes the same call. This is not an alarm: an alert has to reach a phone when this console is down, which is exactly when it is needed.':
    'Executar uma pede uma rodada agora em vez de esperar a próxima noite. Fica registrado ' +
    'com o seu nome — a linha da própria execução não consegue dizer quem pediu, porque o ' +
    'agendador faz a mesma chamada. Isto não é um alarme: um alerta tem de chegar a um ' +
    'telefone quando este console está fora do ar, que é exatamente quando ele é preciso.',
  'Nothing here can start a job. This deployment is not running on Cloud Run, so there is nothing to ask — which is the ordinary state of a laptop, of the local stack and of the test suite. A failed night still runs again on the next one.':
    'Nada aqui consegue executar uma rotina. Este deploy não está rodando no Cloud Run, ' +
    'então não há a quem pedir — que é o estado comum de um laptop, da pilha local e da ' +
    'suíte de testes. Uma noite que falhou roda de novo na noite seguinte assim mesmo.',

  'These are the seeded students and nobody else. They were written by `cmd/seed` to exercise this machinery and none of them exists.':
    'Estes são os alunos semeados e mais ninguém. Foram escritos pelo `cmd/seed` para ' +
    'exercitar esta maquinaria e nenhum deles existe.',
  'This counts the seeded students as well as the real ones. The shape of it is a demonstration, not a measurement of anybody\'s behaviour.':
    'Isto conta os alunos semeados junto com os reais. O formato disto é uma demonstração, ' +
    'não uma medição do comportamento de ninguém.',

  /* THE EIGHT STEPS OF THE FUNNEL, in `internal/analysis/funnel.go`. The ORDER
     is the product and lives there; these are only the words. */
  'Arrived': 'Chegou',
  'Created an account': 'Criou uma conta',
  'Verified the address': 'Confirmou o endereço',
  'Chose a track': 'Escolheu uma trilha',
  'Opened the first lesson': 'Abriu a primeira aula',
  'Finished the first section': 'Concluiu a primeira seção',
  'Finished the free course': 'Concluiu o curso gratuito',
  'Subscribed': 'Assinou',
  'nothing creates a subscription until there is a payment gateway, so there is no event to count. A missing feature and not a step nobody reaches':
    'nada cria uma assinatura enquanto não houver um gateway de pagamento, então não há ' +
    'evento a contar. Uma funcionalidade que falta, e não uma etapa a que ninguém chega',

  'This is what the nightly job wrote, and that job counts real people only — it takes questions out of circulation, which must never happen on the strength of students who were invented.':
    'Isto é o que a rotina noturna escreveu, e essa rotina conta apenas pessoas reais — ela ' +
    'tira questões de circulação, o que jamais pode acontecer com base em alunos que foram ' +
    'inventados.',
  /* THE TWO SENTENCES THAT SAY WHICH BASIS A TABLE IS ON. They replace the one
     that used to explain why the second basis could not be built — it can, so
     the explanation is gone and what is left is the choice. Written in Go, so
     `check-interface` cannot see them. */
  'Grouped by the month each person signed up. This asks whether the product holds the people it attracts.':
    'Agrupado pelo mês em que cada pessoa se inscreveu. Isto pergunta se o produto segura ' +
    'as pessoas que ele atrai.',
  'Grouped by the month each person first started paying, and only the people who did. This asks whether the product holds the people who paid, which is a different population — and a school where signups stay and subscribers leave has a problem no signup cohort can show.':
    'Agrupado pelo mês em que cada pessoa começou a pagar, e apenas quem pagou. Isto ' +
    'pergunta se o produto segura as pessoas que pagaram, que é outra população — e uma ' +
    'escola onde os inscritos ficam e os assinantes vão embora tem um problema que nenhuma ' +
    'coorte por inscrição consegue mostrar.',

  /* ---------- the tab that is older than the build ---------- */
  'This console has been open since before the last update. Reload it when you are ready.':
    'Este console está aberto desde antes da última atualização. Recarregue quando puder.',
  'Reload': 'Recarregar',
};
