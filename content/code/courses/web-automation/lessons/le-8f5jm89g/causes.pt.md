---
title: Seis causas, cada uma com um caso
version: 1
---

**Um teste instável tem uma causa, e a causa quase sempre é uma de seis.** A crença comum é que a
instabilidade é como o tempo lá fora: o navegador estava lento, a máquina estava ocupada,
acontece. Máquinas ocupadas existem, mas só importam quando algo no teste ou na página depende de
um tempo que nunca foi garantido. Dar nome à causa é o que transforma *acontece* numa correção.
Cada uma abaixo traz um caso desta loja e um da plataforma em que você estuda, cujas suítes
passaram por todas elas.

| causa | o que muda entre execuções | a loja | a plataforma |
|---|---|---|---|
| tempo | quem termina primeiro, a página ou a verificação | a busca da aula 3 | um cartão de curso lido cedo demais |
| estado compartilhado | o que outro teste fez enquanto isso | a cesta única | dois pacotes de teste, um banco de dados |
| ordem | o que um teste anterior deixou para trás | uma cesta que ninguém esvaziou | capturas de tela tiradas em outra ordem |
| ambiente | o que a máquina alcança ou tem instalado | nenhum ainda | fontes vindas de uma CDN |
| o próprio teste | um valor aleatório ou o relógio, no teste | o id de cartão da aula 2 | um código de um em um milhão |
| a aplicação | a página se comporta mesmo de outro jeito | a busca, digitada a 145 ms | o embaralhamento do treino |

## Tempo

O teste olha a página enquanto ela ainda está a caminho de algum lugar. A aula 3 conta essa
história inteira para esta loja: o teste que dormia meio segundo passava, o que dormia um segundo
inteiro falhava, e o que lia na hora não achava nada. Cada um desses vereditos dependia de quanto
o servidor demorou naquele dia.

A plataforma teve a mesma corrida num teste que visita cada curso e verifica o que o cartão no pé
da página oferece. A interface passa de um curso para outro mudando a parte do endereço depois do
`#`, o que não carrega uma página nova: o `goto` do Playwright volta assim que o endereço mudou, e
a tela é redesenhada um instante depois. **Lido nesse intervalo, o cartão é o do curso anterior.**
A suíte chegou a dizer que um curso sem prova oferecia uma, porque estava lendo o cartão do curso
de antes. Ela passava no CI com um conjunto de poucos cursos, em que ganhava a corrida, e perdeu a
corrida no catálogo de verdade. A correção espera que o título nomeie o curso pedido, o mesmo
movimento que a aula 3 fez com o `aria-busy`.

## Estado compartilhado

Dois testes mexem na mesma coisa ao mesmo tempo, e cada um está certo sozinho. O
`tests/ssr.spec.js` da aula 6 esvazia a cesta com `POST /api/reset`, põe uma banana e espera uma
contagem de 1. O `tests/waiting.spec.js` da aula 10 também começa com um reset, põe uma manga, e só
verifica a mensagem que avisa isso. Cada arquivo tem um teste; `--repeat-each 10` roda cada teste
dez vezes. Com um worker, as vinte execuções se revezam:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --workers 1 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  20 passed (1.0m)
```

Com dois workers, duas delas rodam ao mesmo tempo contra a cesta única:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --workers 2 | grep -E '^  [0-9]+ (failed|flaky|passed)|Expected:|Received:'
    Expected: "1"
    Received: "2"
    Expected: "1"
    Received: "2"
    Expected: "1"
    Received: "2"
  3 failed
  17 passed (43.0s)
```

Nada mudou em nenhum dos arquivos. Uma contagem de 2 quer dizer que a manga chegou entre o reset
e a verificação do teste do ssr. **Passar sozinho e falhar junto é a assinatura do estado
compartilhado**, e mudar o `--workers` é como você a enxerga. A aula 15 dá a cada teste dados só
seus, que é a correção; a aula 19 trata de rodar a suíte em paralelo de propósito.

A plataforma encontrou isso nos seus testes em Go, que rodam muitos pacotes ao mesmo tempo contra
um único banco de dados. Dois pacotes inseriam, cada um, uma escola com o mesmo nome fixo, `code`, e
o índice único deixava entrar só uma delas. Qual perdia era questão de tempo. Passou num notebook e
depois chegou ao CI como uma chave duplicada levantada em dois pacotes ao mesmo tempo. Desde então a
regra do repositório é que um teste nunca semeia um valor único fixo e só faz afirmações sobre as
linhas que ele mesmo escreveu.

## Ordem

Um teste passa ou falha conforme o que rodou antes dele. O reset no topo de todo teste da cesta
existe por esse motivo: o comentário do `tests/ssr.spec.js` da aula 6 diz isso, *a cesta é
compartilhada, então todo teste começa por esvaziá-la*. Sem ele, um teste que espera uma contagem
de 1 só passa quando calha de rodar primeiro. O reset resolve a ordem; como a captura acima mostra,
não faz nada por dois testes rodando no mesmo instante.

O caso da plataforma não tinha nada a ver com navegador. As imagens de programas de terminal dos
seus cursos são tiradas por uma ferramenta que abre o programa e digita nele, e o `vim` guarda na
pasta pessoal um arquivo que o leva de volta à última linha em que você estava. Assim, cada tela
dependia de quais telas tinham sido tiradas antes, e em que ordem. Quando todas tiveram de ser
tiradas de novo, uma verificação que confere cada receita contra a imagem publicada achou quatro
receitas erradas, e esse arquivo era a causa que ninguém tinha imaginado.

## Ambiente

O mesmo código e o mesmo teste dão outro veredito em outra máquina. O teste de grafo da plataforma
desenha cada trilha em seis tamanhos de janela e falha se uma linha cruza um cartão. Ele falhava na
máquina de build em dois tamanhos e em nenhum no ambiente de desenvolvimento. A interface carregava
as fontes de uma CDN de fontes: a máquina de build alcançava a CDN e o ambiente de desenvolvimento
não, então **as duas máquinas mediam os cartões em fontes diferentes**. Foram três rodadas de
palpites até alguém perguntar quais fontes tinham carregado. Hoje as fontes são servidas pela
própria plataforma, e o teste ainda imprime na primeira linha quais recebeu, para que a pergunta
esteja respondida antes de alguém precisar fazê-la. A loja ainda não tem um caso assim, e a aula 21
de `manual-testing` trata de ambientes em geral.

## O próprio teste

O teste traz a sua própria aleatoriedade ou o seu próprio relógio. O teste da aula 2 usava um id de
cartão copiado do DevTools, e a loja sorteia um id novo a cada carregamento: o teste falhou na
primeira execução, e só passaria no raro carregamento que sorteasse o mesmo número de novo.

A plataforma mantém um desses de propósito. Um teste do segundo fator no login cadastra o código
`000000` e espera que ele seja recusado. Cada cadastro gera um segredo novo, e `000000` é o código
certo para ele mais ou menos uma vez em um milhão, e o comentário ao lado diz que uma falha ali *é
ganhar na loteria, e não um defeito*. **Uma taxa calculada e escrita é uma decisão.** Uma taxa que
ninguém mediu é o assunto do resto desta aula.

## A aplicação

Às vezes a própria página faz coisas diferentes em execuções diferentes, e o teste está certo em
falhar quando ela faz. Este é o caso em que repetir o teste faz mais estrago, porque a instabilidade
é o defeito aparecendo.

A suíte de acessibilidade da plataforma verifica a tela de treino nos seus dois resultados, certo e
errado. Qual dos dois aparecia dependia da ordem em que as questões eram embaralhadas, então uma
cor fraca demais num deles era apontada mais ou menos uma vez a cada três execuções e passava nas
outras. Hoje a suíte pede cada resultado pelo nome, e o defeito aparece em toda execução. O caso da
loja é a busca da aula 3, digitada um pouco mais rápido do que uma pessoa digita, e a próxima seção
mede isso.
