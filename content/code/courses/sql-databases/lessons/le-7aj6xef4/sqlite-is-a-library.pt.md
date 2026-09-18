---
title: SQLite não é um servidor
version: 1
---

A imagem comum do SQLite é "o pequeno" — um banco para brinquedos, a ser trocado por um de verdade
quando o projeto crescer. Essa imagem está errada duas vezes, e substituí-la é o ponto desta seção.

Ele não é uma versão menor dos outros três. É **outro tipo de coisa**, e a diferença não é tamanho.
PostgreSQL, MySQL e MariaDB são programas que rodam por conta própria, escutando num socket; sua
aplicação conecta a um deles e manda instruções. O SQLite é uma biblioteca contra a qual seu
programa é ligado, e a "conexão" é uma chamada de função dentro do seu próprio processo. O banco é
um arquivo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois arranjos lado a lado. À esquerda, rotulado um servidor, três caixas de aplicação separadas cada uma com um driver, e uma seta de cada uma atravessa uma fronteira vertical tracejada marcada socket até uma caixa do servidor de banco de dados, que é um processo próprio; uma seta aponta para baixo do servidor até uma caixa marcada arquivos de dados. Uma nota diz muitos escritores ao mesmo tempo e que o servidor os serializa. À direita, rotulado uma biblioteca, há uma única caixa de aplicação com a biblioteca SQLite desenhada dentro dela, sem fronteira atravessada, e uma seta reta para baixo até uma caixa marcada shop.db. Uma nota diz um escritor por vez, uma chamada de função em vez de um socket, sem nada para subir e nada a que conectar.\"><text x=\"14\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">um servidor: PostgreSQL, MySQL, MariaDB</text>\n<rect x=\"14\" y=\"44\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"69\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 1</text>\n<text x=\"69\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">driver</text>\n<rect x=\"14\" y=\"100\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"69\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 2</text>\n<text x=\"69\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">driver</text>\n<rect x=\"14\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"69\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 3</text>\n<text x=\"69\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">driver</text>\n<line x1=\"210\" y1=\"34\" x2=\"210\" y2=\"248\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line>\n<text x=\"210\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um socket, e uma fronteira de processo</text>\n<path d=\"M124 64 L190 64 L190 100 L250 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M240 94 L250 100 L240 106\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M124 120 L250 120\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M240 114 L250 120 L240 126\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M124 176 L190 176 L190 140 L250 140\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M240 134 L250 140 L240 146\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<rect x=\"250\" y=\"88\" width=\"130\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n<text x=\"315\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o servidor</text>\n<text x=\"315\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">processo próprio</text>\n<path d=\"M315 153 L315 190\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M309 180 L315 190 L321 180\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<rect x=\"250\" y=\"190\" width=\"130\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"315\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">arquivos de dados</text>\n<text x=\"14\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">muitos escritores ao mesmo tempo;</text>\n<text x=\"14\" y=\"240\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o servidor os serializa</text>\n<line x1=\"410\" y1=\"12\" x2=\"410\" y2=\"288\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"436\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">uma biblioteca: SQLite</text>\n<rect x=\"436\" y=\"60\" width=\"254\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n<text x=\"563\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app 1</text>\n<rect x=\"466\" y=\"100\" width=\"194\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect>\n<text x=\"563\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a biblioteca SQLite</text>\n<path d=\"M563 153 L563 190\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M557 180 L563 190 L569 180\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<rect x=\"498\" y=\"190\" width=\"130\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n<text x=\"563\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop.db</text>\n<text x=\"436\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um escritor por vez; uma chamada de função,</text>\n<text x=\"436\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não um socket. Nada para subir,</text>\n<text x=\"436\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada a que conectar.</text></svg>", "caption": "A diferença estrutural, e todo o resto desta seção decorre dela. À esquerda uma instrução atravessa uma fronteira de processo; à direita ela não atravessa nada."}
```

## O que isso compra

**Nada para subir.** Sem daemon, sem porta, sem usuário, sem senha, sem arquivo de configuração. O
banco é `shop.db` e abri-lo é abrir um arquivo. Uma suíte de testes cria um por teste e apaga; a
ferramenta de migração da aula 11 não tem o que esperar.

**Sem rede no caminho.** Ler uma linha é uma chamada de função e uma leitura de página, não uma ida
e volta. Para uma aplicação de um processo só que lê muito, o SQLite é rotineiramente mais rápido
que um servidor na mesma máquina, porque a chamada de rede mais rápida é a que não acontece.

**Um arquivo para mover.** Backup é `cp`. Distribuir um conjunto de dados somente-leitura junto da
aplicação é distribuir um arquivo. É por isso que ele está dentro de todo celular.

**E é totalmente relacional e totalmente transacional.** Chaves estrangeiras, `CHECK`, funções de
janela, CTEs, `BEGIN`/`COMMIT`, recuperação de queda. As garantias da aula 8 valem; não é um
armazém chave-valor com SQL pintado por cima.

## O que isso custa, e é uma coisa só

**Um escritor por vez, para o arquivo inteiro.** Não um por tabela, não um por linha — um por
banco. Aqui está o que um segundo escritor encontra enquanto o primeiro ainda tem uma transação
aberta:

```
sqlite> UPDATE products SET price = 199.00 WHERE sku = 'MS-204';
Error: stepping, database is locked (5)
```

Leitores não são bloqueados por esse escritor, e enxergam o valor confirmado em vez do não
confirmado:

```
sqlite> SELECT sku, price FROM products WHERE sku = 'KB-101';
sku     price
------  -----
KB-101  349.9
```

A mitigação usual é o **log de escrita antecipada**, que é uma instrução e vale ligar toda vez:

```
sqlite> PRAGMA journal_mode;
journal_mode
------------
delete      
sqlite> PRAGMA journal_mode = WAL;
journal_mode
------------
wal         
sqlite> PRAGMA journal_mode;
journal_mode
------------
wal         
```

Ligar imprime o modo em que ele terminou, que é a resposta e não um eco: a troca pode falhar, e um
`PRAGMA` que voltou `delete` é uma troca que não aconteceu.

No modo WAL leitores e o único escritor avançam juntos, o que remove a maior parte da disputa que
as pessoas encontram. Não remove o limite: continua havendo **um** escritor. Um tempo de espera —
o driver aguarda em vez de falhar na hora — transforma "database is locked" numa fila, e uma fila
está bem até a taxa de chegada passar o que um escritor consegue drenar.

O segundo custo decorre do primeiro e costuma ser o decisivo: **o arquivo tem que estar na máquina
em que o código roda.** Três servidores de aplicação atrás de um balanceador não conseguem
compartilhar um arquivo SQLite. Um sistema de arquivos em rede também não é suportado: o
travamento do SQLite depende de travas de arquivo que NFS e parecidos implementam de forma pouco
confiável. No momento em que a resposta a "onde isto roda" é "em várias máquinas",
o SQLite está fora, e nenhum ajuste muda isso.

## Então onde ele cabe

| cabe | porque |
|---|---|
| uma aplicação de desktop ou celular | um processo, arquivo local, sem servidor a instalar |
| uma suíte de testes | criar, usar, apagar, em milissegundos |
| uma ferramenta de linha de comando com estado | o estado é um arquivo que o usuário pode copiar |
| um dispositivo embarcado ou de borda | não há onde rodar um servidor |
| um site de muita leitura numa máquina só | leituras não disputam, e não há ida e volta |
| distribuir um conjunto de dados | o conjunto de dados é o banco |

| não cabe | porque |
|---|---|
| várias máquinas escrevendo | um arquivo, travas locais |
| uma carga de muita escrita | um escritor, seja qual for o hardware |
| muitos clientes simultâneos que você não controla | as conexões são do seu processo, não de um servidor |
| qualquer coisa que precise de usuários e permissões | não existem; permissão de arquivo é todo o modelo |

O resumo honesto é que a pergunta não é *quão grandes são os dados*. O SQLite dá conta de um banco
maior do que a maioria das empresas tem. A pergunta é **quantos processos escrevem nele**, e a
resposta que o descarta é "mais de uma máquina".
