/* ==========================================================================
   Schooling — português do Brasil

   THE KEY IS THE ENGLISH STRING, so this file is the whole of Portuguese and
   there is no `en` file at all: English needs no dictionary, because a string
   with no entry falls back to its key and the key is already what to show.

   A STRING THAT IS THE SAME IN BOTH LANGUAGES STILL GETS AN ENTRY, mapping to
   itself. `Schooling` is the product's name and `E-mail` is spelt the same way
   in both — without the entry, the interface-string checker would report them
   on every run, and a checker with permanent known failures is a checker
   nobody reads. An entry here means somebody decided; an absence means nobody
   has looked yet.
   ========================================================================== */

window.I18N = window.I18N || {};
window.I18N.pt = {
  ui: {
    /* ---------- the chrome ---------- */
    'Schooling': 'Schooling',
    'Skip to content': 'Ir para o conteúdo',
    'Menu': 'Menu',
    'Search': 'Buscar',
    'Search courses and lessons': 'Buscar cursos e aulas',
    'Language': 'Idioma',
    'Theme': 'Tema',
    'You': 'Você',
    'Sign out': 'Sair',

    /* ---------- the catalogue ---------- */
    'Courses': 'Cursos',
    'What there is to learn here.': 'O que há para aprender aqui.',
    'Everything else': 'Todo o resto',
    'Nothing here yet.': 'Ainda não há nada aqui.',
    'Nothing here matches that.': 'Nada aqui corresponde a isso.',
    'Free': 'Grátis',
    'Subscription': 'Assinatura',

    /* ---------- a course, a lesson ---------- */
    'Course': 'Curso',
    'Lesson': 'Aula',
    'sections': 'seções',
    'complete': 'concluído',
    'This course is part of the subscription.': 'Este curso faz parte da assinatura.',
    'Back to the course': 'Voltar ao curso',
    'Mark as done': 'Marcar como concluída',
    'Done': 'Concluída',

    /* ---------- what a student has done ---------- */
    'Your study': 'Seus estudos',
    'Carry on where you left off': 'Continue de onde parou',
    'You have not started anything yet.': 'Você ainda não começou nada.',

    /* ---------- sitting an exam ---------- */
    'Exam': 'Prova',
    'The exam': 'A prova',
    'Sit the exam': 'Fazer a prova',
    'Sign in to sit it': 'Entre para fazê-la',
    'Pass it and the certificate is yours.': 'Seja aprovado e o certificado é seu.',
    'Answers are saved as you make them.': 'As respostas são salvas conforme você responde.',
    'Saving…': 'Salvando…',
    'Saved': 'Salva',
    'Not saved': 'Não salva',
    'Hand in': 'Entregar',
    'Hand in this exam? You cannot change your answers afterwards.':
      'Entregar esta prova? Depois não dá para mudar as respostas.',
    'questions on this paper cannot be answered here yet.':
      'questões desta prova ainda não podem ser respondidas aqui.',
    'This kind of question cannot be answered here yet.':
      'Este tipo de questão ainda não pode ser respondido aqui.',
    'Put these in order, using the arrows.': 'Coloque em ordem, usando as setas.',
    'Move up': 'Subir',
    'Move down': 'Descer',
    'choose': 'escolha',
    'Blank': 'Lacuna',
    'Your answer': 'Sua resposta',
    'Unit': 'Unidade',

    /* ---------- and what it came to ---------- */
    'Passed': 'Aprovado',
    'Not passed': 'Não aprovado',
    'pass mark': 'nota de corte',
    'You can sit this exam again.': 'Você pode fazer esta prova de novo.',
    'Your answers': 'Suas respostas',
    'Right': 'Certa',
    'Wrong': 'Errada',
    'Your exams': 'Suas provas',
    'Still open': 'Em aberto',

    /* ---------- certificates ---------- */
    'Your certificates': 'Seus certificados',
    'A certificate arrives when you pass an exam.': 'O certificado chega quando você é aprovado em uma prova.',
    'Verify a certificate': 'Verificar um certificado',
    'This certificate is genuine.': 'Este certificado é autêntico.',
    'No certificate has that code.': 'Nenhum certificado tem esse código.',

    /* ---------- signing in ---------- */
    'Sign in': 'Entrar',
    'Create an account': 'Criar uma conta',
    'I already have an account': 'Já tenho uma conta',
    'E-mail': 'E-mail',
    'Password': 'Senha',
    'Your name': 'Seu nome',
    'This is the name that goes on your certificates.':
      'É este o nome que vai nos seus certificados.',
    'That did not work.': 'Isso não funcionou.',

    /* ---------- when something is wrong ---------- */
    'Not found': 'Não encontrado',
    'There is nothing at that address.': 'Não há nada nesse endereço.',
    'Back to the courses': 'Voltar aos cursos',
    'Something went wrong': 'Algo deu errado',
    'Check your connection and try again.': 'Verifique sua conexão e tente de novo.',
  },
};
