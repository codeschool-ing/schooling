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

  /* ---------- the tab that is older than the build ---------- */
  'This console has been open since before the last update. Reload it when you are ready.':
    'Este console está aberto desde antes da última atualização. Recarregue quando puder.',
  'Reload': 'Recarregar',
};
