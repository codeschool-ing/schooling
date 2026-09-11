---
title: Que tamanho um pedaço pode ter
version: 1
---

Um cabo não carrega um quadro de qualquer tamanho. Todo enlace tem um teto para quanto pode viajar
de uma vez, e esse teto se chama **MTU** — a unidade máxima de transmissão.

Na Ethernet comum ele é de **1500 bytes**. Não é um número redondo, nem uma lei da física: é um
valor escolhido nos anos 1970, equilibrando o custo do rótulo contra o quanto se perde quando um
quadro é corrompido, e ele sobreviveu a todos os motivos pelos quais foi escolhido simplesmente por
ser o que todo o resto já espera.

## Por que existe um teto

Suponha que não houvesse nenhum, e uma máquina pudesse colocar um quadro de dez megabytes num cabo
compartilhado.

Duas coisas dão errado. A primeira é que, enquanto esse quadro está sendo transmitido, **mais
ninguém consegue usar a linha**. Todas as outras máquinas esperam por ele, e um quadro curto e
urgente — uma tecla, uma amostra de voz — espera atrás de dez megabytes do arquivo de alguém. A
linha deixa de ser compartilhada em qualquer sentido útil.

A segunda é que um quadro é verificado como um todo. Se um único bit for corrompido, o quadro
inteiro é descartado. A 1500 bytes, uma corrupção custa 1500 bytes. A dez megabytes ela custa dez
megabytes, e num enlace com qualquer taxa de erro você passaria a vida reenviando quadros enormes
que quase chegaram.

Então: um teto, baixo o suficiente para que a linha seja compartilhada com justiça e uma perda saia
barata.

## O que acontece quando um pacote é grande demais

Agora o caso interessante. Um pacote está viajando e chega a um roteador cujo próximo enlace tem uma
MTU **menor** do que aquele por onde ele entrou.

Há exatamente duas coisas que o roteador pode fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Um pacote de 4000 bytes encontrando um enlace com MTU de 1500. Acima, ele é cortado em três fragmentos de 1480, 1480 e 1040 bytes. Abaixo, a alternativa: ele é recusado e uma mensagem volta ao remetente dizendo que o pacote era grande demais.\"><rect x=\"14\" y=\"20\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"114\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um pacote — 4000 bytes</text><rect x=\"258\" y=\"14\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"304\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">próximo enlace</text><text x=\"304\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MTU 1500</text><path d=\"M214 40 L254 40\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"380\" y=\"14\" width=\"326\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"392\" y=\"26\" width=\"110\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"447\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1480</text><rect x=\"508\" y=\"26\" width=\"110\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"563\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1480</text><rect x=\"624\" y=\"26\" width=\"70\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"659\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1040</text><text x=\"543\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">CORTAR — três fragmentos, remontados só no fim</text><text x=\"543\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">perca qualquer um deles e os três foram desperdiçados</text><rect x=\"14\" y=\"152\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"114\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um pacote — 4000 bytes</text><text x=\"114\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">marcado \"não fragmentar\"</text><rect x=\"258\" y=\"146\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"304\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">próximo enlace</text><text x=\"304\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MTU 1500</text><path d=\"M214 172 L254 172\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M254 192 C 200 226, 160 226, 118 200\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"380\" y=\"146\" width=\"326\" height=\"52\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".1\" stroke=\"var(--amber)\"></rect><text x=\"543\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recusado, e uma mensagem volta AO remetente:</text><text x=\"543\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">grande demais — o máximo que aceito é 1500</text><text x=\"543\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">DEVOLVER — e espera-se que o remetente tente menor</text><text x=\"543\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que só funciona se essa mensagem de fato chegar</text></svg>", "caption": "Duas maneiras de lidar com um pacote que não cabe. A segunda é a que as redes modernas usam, e a que falha em silêncio."}
```

**Cortar.** O roteador divide o pacote em fragmentos, cada um pequeno o bastante para caber, cada um
com o próprio cabeçalho carregando informação suficiente para dizer onde ele se encaixa. Eles viajam
independentemente e são **remontados no destino final** — não no próximo roteador, e em lugar nenhum
no meio do caminho.

Esse último detalhe é o que torna a fragmentação pouco atraente. Nada no caminho remonta o pacote,
então cada fragmento carrega o próprio risco de ser perdido, e perder qualquer um deles desperdiça
todos. Um pacote de 4000 bytes cortado em três tem três chances de falhar em vez de uma.

**Recusar.** O remetente pode marcar um pacote como *não fragmentar*, e então um roteador que não
consiga passá-lo precisa jogá-lo fora e mandar uma mensagem de volta: *grande demais, e o máximo que
eu aceito são tantos bytes.* Espera-se que o remetente receba isso, diminua os pacotes e tente de
novo.

Esse segundo arranjo é o que as redes modernas usam, e funciona bem — até o momento em que a
mensagem não chega.

## A falha que não se parece com nenhuma outra

Aqui está um formato que você vai encontrar na vida real, então vale saber reconhecê-lo.

Alguém se conecta a uma VPN, ou levanta um tipo específico de túnel, e relata que *a internet está
quebrada* — só que não está, não exatamente. Coisas pequenas funcionam perfeitamente. Entrar na
conta funciona. Páginas curtas carregam. Aí uma página trava, para sempre, sem nada na tela.

O padrão é a pista, e é sempre o mesmo: **requisições pequenas funcionam e transferências grandes
travam.**

O que está acontecendo é isto. O túnel embrulha cada pacote num cabeçalho extra próprio, o que
significa que o tamanho útil lá dentro é menor — talvez 1420 bytes em vez de 1500. Pacotes pequenos
cabem de qualquer jeito. Um grande não cabe, então um roteador o marca como grande demais e manda a
mensagem de volta.

E em algum lugar no meio, um firewall configurado por alguém que decidiu que aquelas mensagens
pareciam tráfego suspeito está **descartando-as**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"Um remetente, um roteador que recusa um pacote grande demais, e um firewall entre eles descartando a mensagem do roteador, de modo que o remetente nunca fica sabendo. O remetente aparece esperando e retransmitindo o mesmo pacote grande demais.\"><rect x=\"12\" y=\"70\" width=\"116\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"70\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o remetente</text><text x=\"70\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ainda tentando</text><rect x=\"294\" y=\"70\" width=\"116\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"352\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um firewall</text><text x=\"352\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">descarta o aviso</text><rect x=\"576\" y=\"70\" width=\"132\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"642\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um roteador</text><text x=\"642\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">MTU 1420 adiante</text><path d=\"M128 84 L290 84 M414 84 L572 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"350\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">um pacote de 1500 bytes, de novo e de novo</text><path d=\"M572 112 L416 112\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"494\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">\"grande demais, aceite 1420\"</text><text x=\"352\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"var(--amber)\">×</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o remetente nunca é avisado, então nunca diminui</text><text x=\"360\" y=\"202\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">requisições pequenas funcionam — as grandes travam para sempre</text></svg>", "caption": "Um buraco negro: o pacote não passa, o aviso não volta, e o remetente não tem como descobrir nenhum dos dois fatos."}
```

Então o remetente nunca fica sabendo. Ele espera, supõe que o pacote simplesmente se perdeu, e manda
**o mesmo pacote grande demais de novo** — que é recusado de novo, e avisado de novo, e o aviso é
descartado de novo. A conexão trava indefinidamente enquanto tudo que é pequeno na mesma máquina
continua funcionando.

Isso tem um nome, *buraco negro*, e vale levar desta aula por um motivo: é o exemplo mais claro do
curso inteiro de uma falha causada por uma **mensagem que deveria voltar e não voltou**. Quase tudo
o mais que você vai diagnosticar é algo que não conseguiu sair.

## Descobrir o tamanho sem ser avisado

Porque essa falha é comum, os remetentes não confiam simplesmente nos avisos. A maioria dos sistemas
modernos **sonda**: manda pacotes de tamanhos variados e observa quais passam, deduzindo o maior que
sobrevive sem precisar que ninguém lhe diga.

É mais lento do que ser avisado, e funciona quando o aviso está quebrado — o que, dada a seção
acima, é uma coisa razoável de se projetar.

## Um número que vale guardar

A coisa mais útil a levar é o formato da conta, porque é o que as questões no fim desta aula vão
pedir que você faça.

Dos 1500 bytes de um enlace Ethernet, cerca de 20 são o cabeçalho do próprio pacote. Então cabem
mais ou menos **1480 bytes dos seus dados** num pacote — e, se houver TCP, outros 20 vão para o
cabeçalho dele, sobrando por volta de **1460**.

É por isso que uma mensagem de 4000 bytes são três pacotes e não dois, e por que o terceiro está
quase vazio. Cortar qualquer coisa em tamanhos fixos deixa um resto, e o resto custa um pacote
inteiro de rótulo.

## Onde isto te deixa

Há um teto para quanto viaja de uma vez, ele é de 1500 bytes na Ethernet comum, e um pacote que não
cabe ou é cortado — o que multiplica o risco — ou é recusado com uma mensagem de volta ao remetente,
que funciona a menos que alguém esteja descartando essas mensagens.

O pacote agora tem tamanho, rota e um envelope para cada salto. O que ele ainda não tem como dizer é
**para qual programa da máquina de destino ele é** — e essa é a próxima seção.
