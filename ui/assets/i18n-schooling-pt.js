/* ==========================================================================
   Schooling — the Portuguese of the screens this repository owns.

   WHY A SECOND FILE. `i18n-pt.js` beside it is `portal-frontend`'s, copied
   whole and kept syncable on purpose: it is the dictionary of the interface
   that was copied, and every entry in it belongs to a screen over there or on
   the vitrine. Adding to it would make the two files diverge, and the next
   copy would either overwrite these entries or have to be merged by hand.

   So the strings that exist only here live here. Today that is three screens
   the portal has no equivalent of — the two documents and the drill — and the
   sentence the offline copy says on every screen that needs a school.

   IT ADDS RATHER THAN ASSIGNS. The file beside it does
   `window.I18N.pt.ui = { … }`, which replaces; this one merges into whatever
   is already there, and index.html loads it after. Assigning here would throw
   away five hundred entries and nothing would look broken — every one of them
   would simply fall back to its English key.

   THE KEY IS THE ENGLISH STRING, as everywhere: there is no `en` dictionary
   because it would be an identity map.
   ========================================================================== */

window.I18N = window.I18N || {};
window.I18N.pt = window.I18N.pt || {};
window.I18N.pt.ui = Object.assign(window.I18N.pt.ui || {}, {
  /* ---------- the two documents ---------- */
  'Terms of use': 'Termos de uso',
  'Privacy policy': 'Política de privacidade',
  'In effect since': 'Em vigor desde',
  'That document could not be read.': 'Não foi possível ler esse documento.',

  /* ---------- the drill ---------- */
  'Practice': 'Praticar',
  'The questions you are closest to forgetting.':
    'As questões que você está mais perto de esquecer.',
  'Nothing is due. Come back tomorrow.': 'Nada vence hoje. Volte amanhã.',
  'A question comes back when you are about to forget it, not on a timetable.':
    'Uma questão volta quando você está prestes a esquecê-la, não por calendário.',
  'Sign in to practise: the schedule is yours and it lives with the school.':
    'Entre para praticar: a agenda é sua e fica com a escola.',
  'The schedule could not be read.': 'Não foi possível ler a agenda.',
  'due': 'a vencer',
  'drawing…': 'sorteando…',
  'That question could not be drawn.': 'Não foi possível sortear essa questão.',
  'Done for today.': 'Por hoje é só.',
  'Finish': 'Encerrar',
  '{right} of {done} right. Each one comes back further away.':
    '{right} de {done} certas. Cada uma volta mais adiante.',

  /* ---------- the offline copy ---------- */
  'This is the offline copy of this school.': 'Esta é a cópia offline desta escola.',
  /* One line, however long: the interface-string checker reads a key with a
     regular expression that starts at the quote and ends at the colon, and it
     refuses a line it cannot classify rather than half-reading the file. */
  'Courses, tracks and lessons are all here and need no connection. Signing in, your progress and exams live with the school, so they are not.': 'Os cursos, as trilhas e as aulas estão todos aqui e não precisam de conexão. Entrar, o seu progresso e as provas ficam com a escola, então não estão.',

  /* ---------- the three question types the copied client did not have ----------

     `cloze`, `numeric` and `labelling`. Every one of these is read aloud rather
     than seen: the label on a blank inside a sentence, the unit beside a
     number, and — on the labelling question — the sentence that says where a
     student has just put a label. Left in English they would be the only words
     on the exam paper a Portuguese reader could not follow, on the screen where
     following the words is the whole task. */
  'Blank': 'Lacuna',
  'Your answer': 'Sua resposta',
  'Unit': 'Unidade',
  'Choose a label, then click the picture or use the arrow keys.':
    'Escolha um rótulo e depois clique na imagem ou use as setas do teclado.',
  'This question needs a picture that is not here.':
    'Esta questão precisa de uma imagem que não está aqui.',
  /* "63% across, 41% down" — said in words because it is what somebody who
     cannot see the diagram is told about where their label is. */
  'across': 'na horizontal',
  'down': 'na vertical',
  'not placed yet': 'ainda não colocado',

  /* ---------- My account ----------
     The screen the account menu had been linking to since the menu existed.
     `Two-factor` is left as `dois fatores` rather than the English acronym:
     the phrase is not jargon in Portuguese and the person reading it is being
     asked to do something with it. */
  'My account': 'Minha conta',
  'Who you are here, and how you get in.': 'Quem você é aqui, e como você entra.',
  'You': 'Você',

  'Two-factor sign-in': 'Entrada em dois fatores',
  'A code from an app on your phone, as well as your password. Staff accounts cannot open the console without one.': 'Um código de um aplicativo no seu celular, além da sua senha. Contas da equipe não abrem a console sem isso.',
  'Set it up': 'Configurar',
  'Asking for a secret…': 'Pedindo um segredo…',
  'Put this secret into your authenticator app.':
    'Coloque este segredo no seu aplicativo autenticador.',
  'Open it in the app on this device': 'Abrir no aplicativo deste aparelho',
  'Then type the six digits it shows.': 'Depois digite os seis dígitos que ele mostrar.',
  'Turn it on': 'Ativar',
  'Checking…': 'Conferindo…',
  'Two-factor sign-in is on.': 'A entrada em dois fatores está ativa.',
  'It is on. Signing in asks for a code as well as your password.':
    'Está ativa. Entrar pede um código além da sua senha.',

  'Your recovery codes': 'Seus códigos de recuperação',
  'Write these down now. They are shown once and cannot be shown again.':
    'Anote agora. Eles aparecem uma única vez e não podem ser mostrados de novo.',
  'Each one gets you in without your phone, and works once.':
    'Cada um te faz entrar sem o celular, e funciona uma vez só.',
  'Copy them': 'Copiar',
  'Copied.': 'Copiados.',
  'Your browser would not copy them — select them instead.':
    'Seu navegador não copiou — selecione-os na tela.',
  'I have them': 'Já anotei',
  'Counting your recovery codes…': 'Contando seus códigos de recuperação…',
  'Recovery codes left:': 'Códigos de recuperação restantes:',
  'One recovery code left.': 'Resta um código de recuperação.',
  'Could not count your recovery codes.': 'Não foi possível contar seus códigos de recuperação.',
  'Replace the recovery codes': 'Substituir os códigos de recuperação',
  'Making new ones…': 'Gerando novos…',
  'These replace every code you had.': 'Estes substituem todos os códigos que você tinha.',

  'This browser': 'Este navegador',
  'Signing out here ends this sitting. Your work stays where it is.':
    'Sair aqui encerra esta sessão. Seu trabalho continua onde está.',

  /* The name of the group of buttons that jump between questions. */
  'Questions on this paper': 'Questões desta prova',

  /* THE BANNER THAT SAYS SOMEBODY IS LOOKING (K-02), which a student may see in
     any language — a viewing is opened on their account, on their school, and
     the screens they would have seen are the screens it draws. An operator
     reading this in English while the person it names would read it in
     Portuguese is exactly the case, since the two are not the same person.

     'is looking at' AND 'nothing here can be changed' ARE HALVES OF ONE
     SENTENCE and are separate keys because two names sit between them. In
     Portuguese the verb agrees with what precedes it and the order holds:
     "<Operador> está vendo <Aluno> · <Escola> — nada aqui pode ser alterado". */
  'is looking at': 'está vendo',
  'nothing here can be changed': 'nada aqui pode ser alterado',

  /* When the operator's name could not be read. The banner appears either way:
     an unnamed one is worse than a named one and far better than none. */
  'Somebody': 'Alguém',

  'Stop looking': 'Parar de ver',
  'Ending…': 'Encerrando…',
  'that did not work — close the tab instead':
    'não funcionou — feche a aba no lugar',

  /* ---------- saying something is wrong with the material ---------- */

  'something here is wrong': 'tem algo errado aqui',
  'what is wrong?': 'o que está errado?',

  /* The five reasons. They are the server's words and these are the sentences
     beside them — a reason added there and not here is drawn under its own
     word, which reads oddly and can still be chosen. */
  'the answer given as correct is wrong': 'a resposta dada como correta está errada',
  'something here is not true': 'tem algo aqui que não é verdade',
  'something does not work — a video, an image, a link':
    'alguma coisa não funciona — um vídeo, uma imagem, um link',
  'I cannot follow this': 'não consigo acompanhar',
  'something else': 'outra coisa',

  'what did you see? the more exact, the sooner it is fixed…':
    'o que você viu? quanto mais exato, mais rápido a correção…',
  'send': 'enviar',
  'sending…': 'enviando…',
  'reading…': 'lendo…',
  'thank you — somebody will look at this section':
    'obrigado — alguém vai olhar esta seção',
  'you have already told us about this section, and it has not been answered yet':
    'você já nos avisou sobre esta seção, e ainda não respondemos',
  'that did not send': 'não deu para enviar',
  'that could not be loaded': 'não deu para carregar',

  /* The same three sentences about a QUESTION rather than a section. They are
     written out rather than assembled from a noun, because Portuguese does not
     agree with English about where that noun goes — and a sentence built from
     fragments is one no translator can put in order. */
  'something is wrong with this question': 'tem algo errado nesta questão',
  'thank you — somebody will look at this question':
    'obrigado — alguém vai olhar esta questão',
  'you have already told us about this question, and it has not been answered yet':
    'você já nos avisou sobre esta questão, e ainda não respondemos',

  /* ---------- subscribing ----------

     THE SCREEN THAT REPLACED A `mailto:`. Two of these are worth a note.

     "Pix" is absent because it is not a sentence: the Banco Central's rail is
     called Pix in every language, so the screen writes it directly rather than
     asking this file for a translation that cannot exist.

     AND THE TAX-ID SENTENCES SAY WHAT HAPPENS TO THE NUMBER, in both
     languages, because the privacy policy promises it in both: we pass it on
     and keep only the identifier that comes back. A translation that dropped
     the second half would be a promise made in English and not in Portuguese. */
  'Subscribe': 'Assinar',
  'One subscription opens every course, the final exams, the certificates and the material to download.':
    'Uma assinatura abre todos os cursos, as provas finais, os certificados e o material para baixar.',
  'There is nothing on sale here yet.': 'Ainda não há nada à venda aqui.',
  'For how long': 'Por quanto tempo',
  'How you pay': 'Como você paga',
  'A month': 'Um mês',
  'A year': 'Um ano',
  'Two years': 'Dois anos',
  'months': 'meses',
  'Credit card': 'Cartão de crédito',
  'Five per cent off, and it clears in seconds.':
    'Cinco por cento de desconto, e cai em segundos.',
  'In up to twelve instalments, with no interest.': 'Em até doze vezes, sem juros.',
  'In how many instalments': 'Em quantas vezes',
  'Continue to payment': 'Ir para o pagamento',
  'Starting…': 'Começando…',
  'Your CPF or CNPJ': 'Seu CPF ou CNPJ',
  'The payment provider needs it to issue the charge. We send it and keep only the identifier it answers with.':
    'O provedor de pagamento precisa dele para emitir a cobrança. Nós enviamos e guardamos apenas o identificador que ele devolve.',
  'Paying in Brazil needs a CPF or CNPJ. We pass it to the payment provider and do not store it.':
    'Pagar no Brasil exige CPF ou CNPJ. Nós repassamos ao provedor de pagamento e não guardamos.',
  'A CPF has eleven digits and a CNPJ has fourteen.':
    'CPF tem onze dígitos e CNPJ tem quatorze.',
  'Confirm your e-mail address before paying. The banner on any page will send the link again.':
    'Confirme seu e-mail antes de pagar. O aviso em qualquer página envia o link de novo.',
  'The payment provider would not accept those details.':
    'O provedor de pagamento não aceitou esses dados.',
  'That is not on sale here.': 'Isso não está à venda aqui.',
  'The school could not be reached. Nothing has been charged.':
    'Não deu para falar com a escola. Nada foi cobrado.',
  'The payment could not be started, and nothing has been charged. Try again.':
    'Não deu para começar o pagamento, e nada foi cobrado. Tente de novo.',

  /* AND THE INVITATION'S OWN LINE, which is not on that screen but is the thing
     that leads to it. It replaced "escreva para nós e abrimos na sua conta",
     which was true of a `mailto:` and of nothing since. */
  'You pick the term and how to pay on the next screen.':
    'Você escolhe o prazo e a forma de pagamento na próxima tela.',

  /* THE SAME MONEY SAID TWO SMALLER WAYS, under the invitation's price. The
     placeholders survive translation because they are part of the KEY, which is
     what lets Portuguese put "no Pix" after the figure and English put "with
     Pix" — a sentence cut into fragments could do neither. */
  '{amount} with Pix': '{amount} no Pix',
  'or {count}× {amount}, with no interest': 'ou {count}× {amount}, sem juros',

  /* WHAT AN ACCOUNT IS FOR, said on the one screen where somebody is about to
     need one. It replaced a silent redirect to a form headed "pick up where you
     left off", shown to people who had never been here. */
  'Subscribing needs an account. It is what your subscription and everything you study are attached to.':
    'Assinar precisa de uma conta. É a ela que a assinatura e tudo o que você estudar ficam ligados.',
  'Already have one? The same screen signs you in.':
    'Já tem uma? A mesma tela faz seu login.',

  /* WHAT YOU HOLD, ON THE ACCOUNT SCREEN. The sentence about renewing is the
     one that matters most: nothing here renews itself, and somebody who assumes
     otherwise loses access on a day nobody warned them about. */
  'Your subscription': 'Sua assinatura',
  /* NOT 'Checking…', WHICH THIS FILE ALREADY HAS. It belongs to the second
     factor above and means "conferindo o código"; a duplicate key in an object
     literal is silent and the LAST one wins, so reusing the string here would
     have quietly changed a sentence on another screen. */
  'Reading your subscription…': 'Lendo sua assinatura…',
  'This could not be read just now. Nothing has changed.':
    'Não deu para ler isso agora. Nada mudou.',
  'You do not have one. The first course of every track is free, in full.':
    'Você não tem uma. O primeiro curso de cada trilha é gratuito, por inteiro.',
  'See what a subscription opens': 'Veja o que uma assinatura abre',
  'opens': 'abre',
  'every course, exam and certificate': 'todos os cursos, provas e certificados',
  'nothing — it has run out': 'nada — ela venceu',
  'paid': 'pago',
  'runs to': 'vale até',
  'today is the last day': 'hoje é o último dia',
  'one day left': 'falta um dia',
  '{n} days left': 'faltam {n} dias',
  'This does not renew by itself. When the term ends, you buy another.':
    'Ela não se renova sozinha. Quando o prazo acabar, você compra outro.',

  /* THE SEVEN DAYS, ENQUANTO ELES CORREM.

     Art. 49 do Código de Defesa do Consumidor, e os termos de uso repetem com
     todas as letras. A tela onde a pessoa olha o que comprou não dizia nada
     sobre isso, e o único endereço estava no rodapé de um site institucional
     que ela teria que sair do produto para achar.

     One line, however long: `check-interface` lê a chave com uma expressão
     regular que começa na aspa e termina na outra, e uma frase partida num `+`
     é uma frase que ele não enxerga. */
  'Changed your mind? You have until {day} to undo this purchase and get the whole amount back, no reason needed.': 'Mudou de ideia? Você tem até {day} para desfazer esta compra e receber o valor integral, sem precisar de motivo.',

  /* AND EVERYTHING THEY HAVE BOUGHT, IN A TABLE UNDER IT. The block above is
     the state — one price, one date, both overwritten by the next purchase —
     and this is the record, which is what somebody reconciling a card statement
     or questioning a charge actually needs.

     THE HEADINGS ARE LOWER CASE ON PURPOSE, matching `opens`, `paid` and
     `runs to` above: they are labels on a fact rather than sentences, and the
     stylesheet puts them in small capitals either way. */
  'Everything you have bought': 'Tudo o que você já comprou',
  'bought on': 'comprado em',
  'term': 'prazo',
  'how': 'forma',
  'amount': 'valor',
  'access to': 'acesso até',

  /* HOW IT WAS PAID. `Pix` is a proper noun and is the same word in both
     languages — it is here so the dictionary is complete, and so nobody has to
     work out whether its absence was an oversight. */
  'Pix': 'Pix',
  'Card, {n}×': 'Cartão, {n}×',
  'Card, in one': 'Cartão, à vista',

  /* WHAT BECAME OF A PURCHASE THAT BOUGHT NOTHING. `waiting for payment` is a
     Pix code somebody can still pay, which is why the row hands the address
     back beside it; the other two are over. */
  /* A PAID PURCHASE WITH NO DATE. The log only started recording what a payment
     bought in `0043`, so the sales made before it have nothing to join — and
     saying so is the only honest cell. The screen said "não concluída" there
     once, about a year somebody had paid for in full. */
  'not recorded': 'não registrado',

  'waiting for payment': 'aguardando pagamento',
  'not paid': 'não foi paga',
  'not finished': 'não concluída',
  'finish paying': 'terminar de pagar',

  /* ---------- one of something ----------

     THE PLURALS WERE ALREADY THERE AND THE SINGULARS WERE NOT, because until
     now nothing ever said one. Screens wrote `n + ' ' + txt('tracks')`, and a
     course belonging to a single track read "em 1 trilhas".

     THEY LIVE HERE AND NOT IN `i18n-pt.js`, which is the copied dictionary kept
     syncable with the interface it came from — the plurals beside them are that
     file's and stay there. Adding to it is what makes the next copy a merge by
     hand, and the rule does not bend for four words.

     `attempt` is not on this list: the exercises screen needed a singular
     before anybody else did, and it is already over there beside its plural. */
  'lesson': 'aula',
  'track': 'trilha',
  'course': 'curso',
  'section': 'seção',
});
