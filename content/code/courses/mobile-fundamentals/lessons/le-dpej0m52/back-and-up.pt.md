---
title: Voltar, subir, e o que acontece no fundo da pilha
version: 1
---

**Todo celular Android tem um *voltar* do sistema, e um iPhone não tem nenhum.** Essa é a única
diferença de navegação que o sistema impõe, em vez de um designer escolher. No Android, voltar é um
botão na barra de navegação nos aparelhos mais antigos e um deslize a partir de qualquer uma das bordas
da tela nos mais novos. Ele pertence ao sistema, não ao app: o seu app não o desenha nem pode
removê-lo, e só pode decidir o que ele faz. Num iPhone, voltar é um controle que o app desenha. É um
botão de voltar no canto superior esquerdo de uma tela empilhada, com um deslize a partir da borda
esquerda como atalho para ele. As diretrizes da Apple sobre gestos dizem assim: as pessoas "esperam encontrar um
botão Voltar numa barra de ferramentas no alto", e o deslize é oferecido "sem deixar de oferecer o
botão Voltar".

| | Android | iOS |
|---|---|---|
| quem oferece o voltar | o sistema: um botão, ou um deslize a partir de qualquer borda | o app: um botão que ele desenha, e o deslize da borda que a navegação acrescenta |
| numa tela empilhada | desempilha | o botão de voltar desempilha |
| na raiz da primeira aba | o app sai da tela | não há botão de voltar para tocar |
| sobre uma folha ou uma gaveta aberta | fecha | um botão, ou um deslize para baixo, fecha a folha |

## Voltar na raiz

**No Android, voltar na raiz do app leva a aluna para fora dele**, para o que havia antes: a tela
inicial, ou o app que abriu o seu. Os princípios de navegação do Android descrevem a start destination
como "a última tela que eles veem antes de sair do app". O que acontece com o app depois disso mudou no
Android 12. Segundo a documentação do Android sobre as mudanças de comportamento dessa versão, voltar
na tela que o launcher abriu, na raiz da sua tarefa, agora move a tarefa para segundo plano, como faz
o gesto de Início, enquanto as versões anteriores encerravam a activity dessa tela. O app não morre
com isso; fica em segundo plano, e a aula 4 diz o que o sistema pode fazer com ele a partir dali.

**No iOS, a raiz de uma pilha simplesmente não tem botão de voltar.** Não há para onde voltar dentro
do app. A pessoa sai de um app no iPhone com o gesto do próprio sistema para ir à tela
inicial, que não é voltar e que o app nunca recebe como um evento de navegação.

**As abas acrescentam mais um passo no Android.** Voltar na raiz de qualquer aba que não seja a
primeira leva à primeira aba, e só voltar na raiz da primeira aba sai do app. Esse é o arranjo comum, e
o que a biblioteca de navegação do Android monta para uma barra inferior. Então a aluna que está em Week
aperta voltar uma vez para chegar a Courses, e mais uma para sair. As duas próximas seções modelam
exatamente isso.

## Predictive back

**A partir do Android 13, um deslize de voltar pode mostrar para onde vai antes de o dedo soltar.** O
Android chama isso de *predictive back*, o voltar preditivo. Enquanto a aluna desliza, a tela atual
encolhe e a de trás aparece; na raiz, a tela do app encolhe sobre um vislumbre da tela inicial. Soltar
o dedo confirma; deslizar de volta cancela. A documentação do Android sobre o gesto de voltar
preditivo, lida em 30 de outubro de 2026, diz que ele ficava atrás de uma opção de desenvolvedor no
Android 13 e 14. A partir do Android 15, as animações do sistema aparecem por padrão nos apps que
aderiram a ele. A consequência para um app é que o sistema precisa saber *antes* de o deslize
terminar se o app vai tratar o voltar sozinho, então o app declara com antecedência qual tela está
respondendo, em vez de reagir depois que o toque já aconteceu.

## Subir não é voltar

**O Android tem uma segunda seta, *up*, subir, e a diferença importa quando a aluna chegou de outro
lugar.** Subir é a seta no canto superior esquerdo da barra do app. Os princípios de navegação do
Android dizem que, dentro da tarefa do próprio app, subir e voltar se comportam igual, e depois citam
duas diferenças:

- **Subir nunca sai do app.** Na start destination não há seta de subir, enquanto voltar continua lá e
  sai.
- **Depois de um link vindo de outro app, os dois se separam.** Voltar devolve ao app de onde a aluna
  veio. Subir vai para a tela *acima* desta na hierarquia do seu app, por uma pilha que a biblioteca de
  navegação monta para a ocasião, porque a aluna nunca passou por ela.

O segundo caso é o assunto da aula 11: um link que abre o planner direto num curso pulou a lista
Courses, e subir precisa saber que ela está lá mesmo assim. No iOS, o botão de voltar no canto superior
esquerdo faz o papel dos dois, e depois de um link vindo de outro app o sistema acrescenta um pequeno
controle na barra de status para voltar ao app de onde a pessoa veio.
