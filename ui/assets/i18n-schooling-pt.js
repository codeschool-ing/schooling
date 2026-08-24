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
});
