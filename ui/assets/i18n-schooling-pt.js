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

  /* The name of the group of buttons that jump between questions. */
  'Questions on this paper': 'Questões desta prova',
});
