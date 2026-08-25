/* ==========================================================================
   The student's own place — the Portuguese of it.

   THIS IS THIS ADDRESS'S DICTIONARY AND NOBODY ELSE'S. The study interface has
   its own two files and they say hundreds of things this screen never says;
   sharing one dictionary between two interfaces would make every string of the
   one read as a stale entry to the other — which is precisely what
   `check-interface` reports, and precisely what it is for. CI runs it against
   this directory as a second invocation, so a string added here without its
   Portuguese fails a pull request exactly as it does over there.

   IT ASSIGNS RATHER THAN MERGES, because at this origin there is nothing to
   merge into: `i18n.js` before it carries es, fr and it, and no other file
   writes `pt`.

   THE KEY IS THE ENGLISH STRING, as everywhere in this organisation: there is
   no `en` dictionary because it would be an identity map.
   ========================================================================== */

window.I18N = window.I18N || {};
window.I18N.pt = window.I18N.pt || {};
window.I18N.pt.ui = {
  /* ---------- the shell ---------- */
  'Mine': 'Meu',
  'Reading…': 'Lendo…',
  'Switch theme': 'Trocar o tema',

  /* ---------- what is due ---------- */
  'Due today': 'Para hoje',
  '1 question': '1 questão',
  '%n questions': '%n questões',
  'and %n more': 'e mais %n',
  'Practise at': 'Praticar em',

  /* ---------- the sentence the SERVER writes ----------

     It arrives in English at run time and is translated at the point of
     display, which is the only arrangement that works: the screen must not
     hold its own copy of the rule, and the server does not know which language
     is being read.

     `check-interface` CANNOT SEE THIS ONE, and says so in its own header — no
     static scan can enumerate a string that arrives over HTTP. So this entry is
     the half nobody checks, and the key has to match `internal/practice/
     across.go` character for character. It was missing once, and the page read
     in Portuguese with one English paragraph under two translated ones. */
  'What is due today, everywhere you practise. Questions you have never answered are not here: those belong to a course you are working through, and each school\'s own practice screen still offers them.':
    'O que está para hoje, em todo lugar onde você pratica. Questões que você nunca respondeu não estão aqui: elas pertencem a um curso que você está percorrendo, e a tela de prática de cada escola continua oferecendo essas.',

  /* ---------- nothing due ---------- */
  'Nothing due': 'Nada para hoje',
  'You have answered everything that came back today. Each school still has questions you have not seen yet.':
    'Você respondeu tudo o que voltou hoje. Cada escola ainda tem questões que você não viu.',

  /* ---------- no session ----------

     "one sign-in covers all of them" is N-01 said to a student, and it is the
     sentence that makes the absence of a form here read as a design rather
     than as something missing. */
  'Sign in at your school': 'Entre pela sua escola',
  'This page is yours, so it needs to know who you are. Sign in at any school you study at and come back — one sign-in covers all of them.':
    'Esta página é sua, então ela precisa saber quem você é. Entre por qualquer escola em que você estuda e volte — uma única entrada vale para todas.',

  /* ---------- the read failed ----------

     It says the queue is fine on purpose: the thing a student would otherwise
     conclude is that they have nothing to practise, and that is the one wrong
     answer they would act on. */
  'That could not be read': 'Não deu para ler isso',
  'Your queue is fine — this page could not reach it. Try again in a moment.':
    'Sua fila está lá — esta página não conseguiu alcançá-la. Tente de novo em instantes.',
};
