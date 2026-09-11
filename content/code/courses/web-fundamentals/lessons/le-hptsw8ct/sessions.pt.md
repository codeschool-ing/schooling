---
title: Uma ficha, e uma tabela
version: 1
---

As leituras anteriores deram a você um lugar para pôr um pedacinho de texto. Esta é sobre o que pôr
ali, e a resposta é: o mínimo possível.

## O formato

O cookie guarda um **identificador** e mais nada. Tudo que esse identificador representa mora no
servidor, numa tabela que o navegador nunca vê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O navegador guarda um identificador curto e opaco. O servidor guarda uma tabela em que esse identificador é uma linha com quem é o visitante, quando a sessão começou e o que mais a aplicação precisar.\"> <rect x=\"20\" y=\"34\" width=\"260\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"150\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o que o navegador guarda</text> <rect x=\"40\" y=\"80\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"150\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">session=8f3c1a9e</text> <path d=\"M286 89 L434 89\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <text x=\"360\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">acha uma linha</text> <rect x=\"440\" y=\"34\" width=\"260\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"570\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o que o servidor guarda</text> <text x=\"570\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">8f3c1a9e</text> <text x=\"570\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">usuário: ana</text> <text x=\"570\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">entrou às 09:14</text> <text x=\"570\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">papel: estudante</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">trinta bytes cruzam a rede; o resto nunca sai do prédio</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e como a verdade está na tabela, apagar a linha encerra tudo de uma vez</text> </svg>", "caption": "Uma ficha de chapelaria. Não vale nada sozinha, e é a única coisa que acha a linha certa."}
```

O cookie é uma ficha de chapelaria. A ficha não vale nada sozinha, não diz nada sobre o que está na
chapelaria, e a única coisa que faz é deixar alguém atrás de um balcão achar a linha certa.

Isso rende quatro coisas de uma vez. O cookie fica minúsculo, então o imposto sobre cada requisição
fica minúsculo. O visitante não consegue mudar o que está nele, porque o valor não tem significado.
Nada sensível cruza a rede depois da primeira vez. E você consegue encerrar uma sessão na hora, do
seu lado, apagando a linha — o que é mais importante do que parece, e a próxima leitura é sobre
quanto custa abrir mão disso.

## O identificador tem que ser impossível de adivinhar

Não um número que cresce. Não um nome de usuário com algo acrescentado. Não algo derivado de algo
que um visitante saiba.

Se a sessão `1041` existe, alguém vai tentar a `1040`, e se funcionar essa pessoa está agora
conectada como quem for a dona. O ataque não precisa de habilidade nem de ferramentas, e já foi
encontrado em sistemas de produção de todos os tamanhos.

A exigência é um valor longo e aleatório vindo de uma fonte feita para segurança, e não de uma
função aleatória comum. Na prática isso é uma chamada ao que a sua linguagem chame de aleatório
seguro, e a razão para conhecer a regra é reconhecer o formato de um erro: um identificador de
sessão que parece um número, ou parece um endereço de e-mail, é um defeito independentemente do que
mais esteja certo.

## Gere outro na porta

Aqui está um ataque que não é óbvio e tem correção de uma linha.

Alguém faz com que você visite um link dele, que carrega um identificador de sessão escolhido por
ele. Seu navegador agora o guarda. Você entra — e se o servidor mantém o mesmo identificador e
simplesmente anexa sua conta a ele, então o identificador que o atacante já conhece é agora uma
sessão conectada.

A correção é **emitir um identificador novo no momento em que o visitante entra**, e jogar o antigo
fora. Custa uma linha, fecha a classe inteira, e é a razão de frameworks terem uma função com algum
nome parecido com *regenerar*.

## Dois relógios

Uma sessão deve acabar, e há duas formas diferentes de decidir quando.

**Tempo ocioso**: acaba um período depois da última requisição. Conveniente, e é o que impede
alguém que se afastou de uma máquina compartilhada de ficar conectado indefinidamente.

**Tempo absoluto**: acaba um tempo fixo depois de começar, ativa ou não. Menos conveniente e bem
mais difícil de contestar, e é por isso que qualquer coisa que lide com dinheiro costuma ter um.

A maioria dos sistemas usa os dois, com o relógio de ociosidade curto e o absoluto longo. Nenhum dos
dois substitui a terceira coisa, que é encerrar de propósito.

## Sair quer dizer apagar a linha

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Sair só limpando o cookie deixa a linha viva no servidor, então um valor copiado ainda funciona. Apagar a linha primeiro encerra a sessão para toda cópia do valor.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">só limpando o cookie</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">este navegador esquece o valor</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a linha continua lá</text> <rect x=\"20\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">qualquer cópia dele ainda entra</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">apagando a linha primeiro</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a linha sumiu</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">toda cópia do valor agora não vale nada</text> <rect x=\"380\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">depois limpe o cookie, por organização</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o cookie é uma cópia; a linha é a sessão</text> </svg>", "caption": "Dois passos, nesta ordem. O que importa é o que o visitante não vê."}
```

Se sair apenas limpa o cookie, então a sessão continua viva no servidor. O cookie sumiu daquele
navegador, e quem tiver copiado o valor antes — de uma máquina compartilhada, de um arquivo de log
que registrou um cabeçalho, de um script — ainda consegue usá-lo.

Então sair são duas ações: apague a linha, e depois limpe o cookie. Nessa ordem, porque a linha é a
que importa e o cookie é apenas a cópia de um navegador.

## Sessões antes de alguém entrar

O vídeo de abertura perguntou quem diz que as três coisas do carrinho são suas, e a resposta é este
mecanismo funcionando antes de haver conta nenhuma.

Um visitante que nunca entrou ainda ganha uma sessão: um identificador, uma linha, e um carrinho na
linha. Nada no arranjo exige que uma pessoa seja conhecida — exige apenas que o mesmo navegador
volte com a mesma ficha.

Entrar então não cria a sessão. Isso **anexa uma conta a uma que já existe**, que é o que faz o
carrinho sobreviver ao login em vez de esvaziar no pior momento possível. E como a seção anterior
disse para emitir um identificador novo naquele ponto, a linha é levada para o novo em vez de
abandonada com o antigo.

Vale ver com clareza, porque é a diferença entre uma loja que funciona e uma loja que as pessoas
desistem de usar: a sessão anônima e a sessão conectada são a mesma maquinaria, e só um campo da
linha mudou.

## Onde a tabela de fato mora

Uma coisa prática, porque é a primeira surpresa quando um site cresce além de uma máquina.

Se a tabela está na memória do servidor, reiniciar o servidor desconecta todo mundo, e rodar dois
servidores desconecta as pessoas aleatoriamente — metade das requisições chega à máquina que nunca
ouviu falar delas. Isto é a ausência de estado da aula anterior vindo cobrar: o protocolo permite
que qualquer máquina responda, e você acabou de tornar isso falso.

A resposta é pôr a tabela em algum lugar que as duas máquinas alcancem — um repositório compartilhado
feito para isso, ou o banco de dados que você já tem. O custo é uma consulta por requisição, que é o
preço de conseguir revogar qualquer coisa na hora. A próxima leitura é sobre quem achou esse preço
alto demais.
