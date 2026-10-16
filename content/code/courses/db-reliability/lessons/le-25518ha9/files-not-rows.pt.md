---
title: Uma cópia dos arquivos, e por que o `cp` não é uma
version: 1
---

O dump da lição 2 reconstruiu o banco a partir de instruções. Um **backup físico** pula as
instruções e copia o que o servidor guarda em disco: o diretório de dados, cada arquivo dele, byte
a byte. Restaurar significa pôr os arquivos de volta e subir um servidor sobre eles. Nenhuma linha
é inserida, nenhum índice é montado, e é por isso que é rápido; é também por isso que ele carrega
tudo o que os arquivos carregam, inclusive o que há de errado com eles.

## A versão simples, com o servidor parado

A cópia física mais segura de um servidor PostgreSQL é a que se tira com ele desligado. Pare,
copie o diretório, suba de novo:

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ sudo cp -a /var/lib/postgresql/16/main cold-copy
ana@vm:~$ sudo pg_ctlcluster 16 main start
ana@vm:~$ sudo du -sh cold-copy
991M	cold-copy
ana@vm:~$ sudo du -sh cold-copy/pg_wal
689M	cold-copy/pg_wal
```

Essa cópia é perfeita, e custou uma indisponibilidade pelo tempo que o `cp` levou. Repare no
segundo número: dos 991 MB, **689 MB são o `pg_wal`**, o write-ahead log que o servidor mantém para
a própria recuperação, inchado aqui pelos três milhões de pedidos que a lição 2 carregou no
`bigshop`. Uma cópia do diretório leva tudo isso, precise ou não.

Um **backup a frio** como esse é uma técnica de verdade, e a certa para um banco que pode se dar ao
luxo de parar toda noite. A maioria não pode, e esse é o problema todo.

## Por que o mesmo `cp` num servidor rodando é uma armadilha

Copiar o diretório de um servidor em funcionamento parece que deveria dar certo, e muitas vezes
parece ter dado. O `cp` lê os arquivos um depois do outro, ao longo de segundos ou minutos,
enquanto o servidor continua mudando todos eles:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo da esquerda para a direita. O cp lê quatro arquivos, de A a D, um depois do outro. Enquanto isso, o servidor continua escrevendo: uma transação escreve no arquivo A depois de A ter sido copiado e no arquivo D antes de D ser copiado, então a cópia guarda a mudança dessa transação em D e não a mudança em A.\"><defs><marker id=\"l3t-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"l3t-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o cp lê</text><rect x=\"130\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo A</text><rect x=\"270\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo B</text><rect x=\"410\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo C</text><rect x=\"550\" y=\"24\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo D</text><path d=\"M130 80 L700 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3t-pa)\"></path><text x=\"690\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o servidor escreve</text><circle cx=\"300\" cy=\"130\" r=\"6\" fill=\"var(--amber)\"></circle><circle cx=\"470\" cy=\"130\" r=\"6\" fill=\"var(--amber)\"></circle><path d=\"M300 124 L190 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3t-am)\" stroke-dasharray=\"5 4\"></path><path d=\"M470 124 L580 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3t-am)\" stroke-dasharray=\"5 4\"></path><path d=\"M306 130 L464 130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"385\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma transação escreve A e D</text><rect x=\"220\" y=\"176\" width=\"330\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a cópia tem o D, não o A</text></svg>", "caption": "Copiar os arquivos de um servidor em funcionamento, um depois do outro. Cada arquivo é copiado num momento diferente, então uma transação que mexeu em dois deles pode estar pela metade na cópia, e nada na cópia avisa."}
```

A cópia guarda cada arquivo **como ele estava num momento diferente**. Uma transação que escreveu
num arquivo já copiado e num ainda não copiado fica pela metade na cópia. Um índice pode apontar
para linhas que a cópia não tem. Ao subir, um servidor sobre essa cópia normalmente roda a
recuperação de queda que rodaria depois de um corte de energia, não encontra nada que reconheça como
errado, e abre. Nada relata problema. O estrago aparece depois, como uma consulta que devolve uma
linha que não deveria, ou uma constraint que deixou de valer.

O que uma recuperação de queda precisa para consertar uma cópia assim é **toda mudança escrita
desde antes de o primeiro arquivo ser lido até depois de o último ser**. O servidor escreve
exatamente isso, no write-ahead log; o que falta ao `cp` é um jeito de dizer "comece a guardar a
partir daqui, e me diga onde é aqui". O PostgreSQL tem essa conversa embutida, e a próxima seção a
mostra.
