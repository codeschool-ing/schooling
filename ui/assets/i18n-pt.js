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

    /* ---------- the words the portal already had ----------
       Taken from `portal-frontend/assets/i18n-pt.js` rather than written here.
       The two interfaces say the same things and should say them with the same
       words; two translations of one sentence is how two products stop looking
       like one. */
    ' of the track': 'da trilha',
    'After': 'Depois de',
    'Continue': 'Continuar',
    'Navigation': 'Navegação',
    'Open navigation': 'Abrir a navegação',
    'Prerequisites': 'Pré-requisitos',
    'Search courses': 'Buscar curso',
    'Your account': 'Sua conta',
    'available': 'disponível',
    'courses on the path': 'cursos no caminho',
    'free': 'grátis',
    'in progress': 'em andamento',
    'level': 'nível',
    'of': 'de',
    'open the course': 'abrir o curso',
    'pick up where you left off': 'continuar de onde parou',
    'sections completed': 'seções concluídas',
    'see the map': 'ver o mapa',
    'see the track map': 'ver o mapa da trilha',
    'completed': 'concluído',
    'subscription': 'assinatura',

    /* This side's own, because this side has screens the portal does not: an
       exam it invites you to at the end of a course and of a track, a
       certificate somebody can verify from the printed code, and a dashboard
       for a student who has not begun. */
    'End of the course': 'fim do curso',
    'End of the track': 'fim da trilha',
    'Genuine': 'autêntico',
    'Start here': 'comece por aqui',

    /* ---------- the chrome ---------- */
    'Schooling': 'Schooling',
    'Skip to content': 'Ir para o conteúdo',
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

    /* The levels a course card carries. They are catalogue values rather than
       interface words, and they are translated anyway: a Portuguese card
       reading `40h · beginner` is half a sentence in each language. */
    'beginner': 'iniciante',
    'intermediate': 'intermediário',
    'advanced': 'avançado',
    'Subscription': 'Assinatura',

    /* ---------- a course, a lesson ---------- */
    'Course': 'Curso',
    'Lesson': 'Aula',
    'Lessons': 'Aulas',

    /* BOTH FORMS, because a count and a plural word concatenated is wrong on
       every "1". English needs the pair and so does Portuguese. */
    'lesson': 'aula',
    'lessons': 'aulas',
    'section': 'seção',
    'sections': 'seções',
    'note': 'anotação',
    'notes': 'anotações',

    'This course is part of the subscription.': 'Este curso faz parte da assinatura.',
    'Back to the course': 'Voltar ao curso',
    'Mark as done': 'Marcar como concluída',
    'Done': 'Concluída',

    /* ---------- what a student has done ---------- */
    'Your study': 'Seus estudos',
    'Hello': 'Olá',
    'You have not started anything yet.': 'Você ainda não começou nada.',
    'Next steps': 'Próximos passos',
    'Catalogue': 'Catálogo',

    /* The three states a course can be in. They are read as a label above a
       course's name — `EM ANDAMENTO`, over `JavaScript` — so they are
       adjectives about the course and not about the student. */

    'on this path': 'neste caminho',

    /* ---------- notes ---------- */
    'Your notes': 'Suas anotações',

    /* ---------- a track, drawn ---------- */
    'Track': 'Trilha',
    'Your track': 'Sua trilha',
    'Choose a track': 'Escolher a trilha',
    'See the whole track': 'Ver a trilha inteira',
    'Choose one': 'Escolha uma',
    'Finish': 'Fim',
    'The final': 'A prova final',
    'The exam for the whole track.': 'A prova da trilha inteira.',
    'Sit the final': 'Fazer a final',

    /* ---------- sitting an exam ---------- */
    'Exam': 'Prova',
    'The exam': 'A prova',
    'Sit the exam': 'Fazer a prova',
    'Sign in to sit it': 'Entre para fazê-la',
    'The exam needs the school': 'A prova precisa da escola',
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

    /* ---------- uma resposta algébrica ----------
       "Escreva em função de x, y." — as letras entram depois, montadas pelo
       chamador, por isso a frase termina onde termina. */
    'Write it in terms of': 'Escreva em função de',
    'You may write it any way you like.':
      'Pode escrever da maneira que preferir.',

    /* ---------- putting labels on a picture ----------
       "63% à direita, 41% abaixo". As duas palavras aparecem sozinhas numa
       lista que um leitor de tela percorre, então cada uma tem de fazer
       sentido sem o número ao lado. */
    'Choose a label, then click the picture or use the arrow keys.':
      'Escolha um rótulo e clique na figura, ou use as setas.',
    'across': 'à direita',
    'down': 'abaixo',
    'not placed yet': 'ainda não colocado',

    /* ---------- os dois documentos ---------- */
    'Terms of use': 'Termos de uso',
    'Privacy policy': 'Política de privacidade',
    'Legal': 'Jurídico',
    'In effect since': 'Em vigor desde',

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

    /* ---------- drilling ----------
       "Volta em 6 dias" — o número entra entre as duas, então "Back in" e
       "days" aparecem separados e cada um tem de funcionar sozinho. */
    'Practice': 'Praticar',

    /* ---------- how you are doing ---------- */
    'Performance': 'Desempenho',
    'How you are doing': 'Como você está indo',
    'You have not answered anything yet.': 'Você ainda não respondeu nada.',
    'correct': 'de acerto',
    'answers': 'respostas',
    'questions met': 'questões vistas',
    'By course': 'Por curso',
    'By question type': 'Por tipo de questão',
    'The rate counts every answer; the two lists below count the most recent answer to each question.':
      'A taxa conta todas as respostas; as duas listas abaixo contam a resposta mais recente de cada questão.',
    'The questions you are closest to forgetting.': 'As questões que você está mais perto de esquecer.',
    'Nothing is due. Come back tomorrow.': 'Nada vence hoje. Volte amanhã.',
    'A question comes back when you are about to forget it, not on a timetable.':
      'Uma questão volta quando você está prestes a esquecê-la, não por calendário.',
    'Loading…': 'Carregando…',
    'Answer': 'Responder',
    'Answer it first.': 'Responda antes.',
    'Back in': 'Volta em',
    'day': 'dia',
    'days': 'dias',
    'Next question': 'Próxima questão',
    'That is everything due today.': 'Isso é tudo que vencia hoje.',

    /* ---------- certificates ---------- */
    'Your certificates': 'Seus certificados',
    'certifies that': 'certifica que',
    'completed': 'concluiu',
    'A certificate arrives when you pass an exam.': 'O certificado chega quando você é aprovado em uma prova.',
    'Verify a certificate': 'Verificar um certificado',
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

    /* ---------- the offline copy ---------- */
    'This is the offline copy of this school.':
      'Esta é a cópia offline desta escola.',
    'Courses, tracks and lessons are all here and need no connection. Signing in, your progress and exams live with the school, so they are not.':
      'Os cursos, as trilhas e as aulas estão todos aqui e não precisam de conexão. Entrar, o seu progresso e as provas ficam com a escola, então não estão.',
  },
};
