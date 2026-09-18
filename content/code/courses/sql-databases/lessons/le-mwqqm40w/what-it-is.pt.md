---
title: A forma dele, e as palavras que ele usa
version: 1
---

O vocabulário do Oracle é mais velho que o da maior parte da indústria e não bate com as palavras
que este curso vem usando. Dois dos descompassos causam confusão de verdade, e vale acertar os
dois antes de qualquer outra coisa.

## Uma instância não é um banco

No PostgreSQL ou no MySQL, "o banco" é vagamente as duas coisas: o servidor em execução e os
arquivos que ele guarda. O Oracle os separa, e a separação sustenta peso.

**O banco** são os arquivos em disco: os dados, os arquivos de controle, os logs de redo. Ele
guarda tudo e não roda nada.

**A instância** é o programa em execução: um bloco de memória compartilhada e um conjunto de
processos de fundo. Ela não guarda dado nenhum e é o que sobe e desce.

Uma instância abre um banco. Normalmente uma instância abre um banco; com o Real Application
Clusters, várias instâncias em várias máquinas abrem **o mesmo** banco ao mesmo tempo, que é a
história de cluster do Oracle e uma das opções cobradas à parte da próxima seção.

## Um banco contém bancos

Desde a 21c a separação vai um nível além e não é mais opcional. Um **banco contêiner** guarda uma
raiz — as tabelas do próprio motor, comuns — e um certo número de **bancos plugáveis**, cada um dos
quais é o que um usuário de PostgreSQL chamaria de banco. Um banco plugável pode ser desplugado de
um contêiner e plugado em outro como uma unidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"Duas caixas lado a lado. À esquerda, uma caixa rotulada a instância, memória e processos, contendo uma caixa para a memória compartilhada e outra para os processos de fundo, com uma nota de que ela sobe e desce, não guarda dado nenhum, e que uma instância serve o contêiner inteiro. Uma seta marcada abre aponta dela para a caixa da direita, rotulada o banco contêiner, arquivos em disco. Dentro dessa caixa uma faixa larga no topo é a raiz, com as tabelas do próprio motor comuns a todos, e abaixo dela três caixas iguais chamadas payroll, billing e claims, cada uma rotulada um banco plugável. Uma nota diz que cada um despluga e pluga em outro contêiner inteiro, e uma segunda nota diz que uma licença paga a máquina sob tudo isto, e não um banco em cima dela.\"><text x=\"14\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">a INSTÂNCIA: memória e processos</text>\n<rect x=\"14\" y=\"40\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect>\n<rect x=\"32\" y=\"60\" width=\"184\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"124\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a memória compartilhada</text>\n<rect x=\"32\" y=\"120\" width=\"184\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"124\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">os processos de fundo</text>\n<text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sobe e desce. Não guarda dado nenhum.</text>\n<text x=\"14\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Uma serve o contêiner inteiro.</text>\n<path d=\"M234 115 L296 115\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M286 109 L296 115 L286 121\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"265\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abre</text>\n<text x=\"306\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">o BANCO CONTÊINER: arquivos em disco</text>\n<rect x=\"306\" y=\"40\" width=\"400\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n<rect x=\"322\" y=\"60\" width=\"368\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"506\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a raiz: as tabelas do próprio motor, comuns a todos</text>\n<rect x=\"322\" y=\"116\" width=\"116\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"380\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payroll</text>\n<text x=\"380\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um banco plugável</text>\n<rect x=\"448\" y=\"116\" width=\"116\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"506\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">billing</text>\n<text x=\"506\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um banco plugável</text>\n<rect x=\"574\" y=\"116\" width=\"116\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"632\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">claims</text>\n<text x=\"632\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um banco plugável</text>\n<text x=\"506\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada um despluga e pluga em outro contêiner inteiro</text>\n<text x=\"306\" y=\"254\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Uma licença paga a máquina sob tudo isto, e não um banco em cima dela.</text></svg>", "caption": "As duas palavras do Oracle para o que os outros motores chamam de uma coisa só. A instância é o programa em execução; o banco é o que está em disco; e desde a 21c um banco é um contêiner com bancos plugáveis dentro."}
```

O motivo de isso importar para quem nunca vai administrar um está na segunda nota daquele desenho:
**a licença é comprada para a máquina, e não para o banco em cima dela.** Três aplicações em três
bancos plugáveis num contêiner é um custo muito diferente das mesmas três em três servidores. Isso
é uma decisão de licenciamento vestida de diagrama de arquitetura, e a próxima seção é sobre quão
frequente isso é aqui.

## O que é um esquema

No Oracle, **um esquema é um usuário.** Criar o usuário `PAYROLL` cria o esquema `PAYROLL`, e as
tabelas dele são `PAYROLL.EMPLOYEES`. Não existe um passo `CREATE SCHEMA` separado que signifique
outra coisa, e não existe um espaço de nomes por banco abaixo desse nível como no PostgreSQL, onde
um banco guarda vários esquemas e um esquema não é um login.

A consequência prática é que **conectar como um usuário te põe num espaço de nomes**, e o mesmo
nome de tabela significa tabelas diferentes para usuários diferentes. Sinônimos existem para
disfarçar isso — `CREATE SYNONYM employees FOR payroll.employees` — e um esquema corporativo
costuma ter muitos.

## As edições, que é onde o custo começa

| edição | o que é |
|---|---|
| Express Edition (XE) | gratuita, inclusive em produção, e limitada: a Oracle publica limites de dados do usuário, memória e threads de CPU que a colocam firmemente na faixa de aprendizado e aplicação pequena |
| Standard Edition 2 (SE2) | uma edição de verdade com um limite rígido de tamanho do servidor, e sem a maioria das opções cobradas à parte |
| Enterprise Edition (EE) | tudo, licenciada por processador, com as opções cobradas por cima |

Quase todo sistema Oracle corporativo é Enterprise Edition. A XE existe e é de fato gratuita, o que
faz dela a coisa certa para instalar se você quiser experimentar qualquer coisa disto — e não é o
que a organização está rodando.

## Uma palavra sobre versões

Os nomes de lançamento mudaram de direção mais de uma vez: 8i e 9i por *internet*, 10g e 11g por
*grid*, da 12c à 19c por *cloud*, e a linha atual é a 23ai. **A 19c é a que esperar em campo**,
porque é o lançamento de suporte longo da linha 12c e um número enorme de sistemas se padronizou
nela.

Isso importa por um motivo que a aula 12 já deu: a disponibilidade de um recurso depende da versão
na sua frente, e o conselho que se acha online sobre Oracle atravessa vinte e cinco anos de
lançamentos sem sempre dizer qual.
