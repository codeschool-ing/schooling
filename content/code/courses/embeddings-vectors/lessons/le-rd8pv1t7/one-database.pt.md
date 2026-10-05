---
title: Um banco ou dois
version: 1
---

A pergunta com que esta aula abriu tem uma resposta que surpreende quem chega das aulas 12 e 13: para
uma loja como a Marginalia, **os vetores pertencem ao banco que ela já roda.** O motivo é a cópia. Um
banco separado guarda uma segunda cópia dos dados, e manter duas cópias em sincronia é um trabalho
que nunca termina.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois desenhos lado a lado. Dois sistemas: a aplicação grava o texto no PostgreSQL no passo 1 e o vetor num banco vetorial separado no passo 2, que pode falhar depois que o passo 1 deu certo; uma busca pede ids ao banco vetorial e depois pede os textos ao PostgreSQL. Um banco: a aplicação manda uma transação e uma consulta ao PostgreSQL, cuja tabela articles guarda o texto e o vetor na mesma linha, ao lado da tabela de pedidos.\"><defs><marker id=\"copiespt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"copiespt-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"copiespt-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">dois sistemas</text><rect x=\"110\" y=\"40\" width=\"140\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aplicação</text><rect x=\"20\" y=\"190\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"90\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">texto, pedidos</text><rect x=\"200\" y=\"190\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">banco vetorial</text><text x=\"270\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vetores</text><path d=\"M140 74 L80 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#copiespt-ah0)\"></path><path d=\"M220 74 L280 188\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#copiespt-ah1)\"></path><text x=\"100\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. grava o texto</text><text x=\"262\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2. grava o vetor</text><text x=\"266\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pode falhar após o 1</text><path d=\"M165 74 L115 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M195 74 L245 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"180\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">busca: ids → busca os textos pelo id</text><path d=\"M392 30 L392 285\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">um banco só</text><rect x=\"480\" y=\"40\" width=\"140\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aplicação</text><path d=\"M550 74 L550 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#copiespt-ah2)\"></path><text x=\"562\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma transação, uma consulta</text><rect x=\"430\" y=\"152\" width=\"240\" height=\"108\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><rect x=\"450\" y=\"186\" width=\"200\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">articles: texto + vetor</text><rect x=\"450\" y=\"222\" width=\"200\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pedidos, contas</text></svg>", "caption": "Com um banco separado, uma gravação são duas gravações e uma busca são duas requisições, e a segunda gravação pode falhar depois da primeira. Com o vetor como coluna, o texto e seu vetor são gravados numa transação e buscados numa consulta.", "same": ["PostgreSQL"]}
```

## Um texto e seu vetor mudam juntos

Quando um artigo muda, duas coisas têm de mudar com ele: o texto e o vetor calculado a partir dele.
Em dois sistemas isso são duas gravações, e a segunda pode falhar depois que a primeira deu certo. Num
banco só é uma transação. Aqui o script que recalcula o vetor do artigo de reembolso tem um bug: ele
carrega o WordLlama em vez do modelo com que a tabela foi construída:

```schooling-example
{
  "language": "python",
  "file": "edit.py",
  "parts": [
    {
      "code": "import psycopg\nfrom pgvector.psycopg import register_vector\nfrom wordllama import WordLlama\n\nbody = \"We refund within two working days of the return reaching our warehouse.\"\nwl = WordLlama.load()",
      "note": "O novo texto do artigo de reembolso, e o modelo que vai transformá-lo em vetor. O bug está aqui: WordLlama, 256 dimensões, onde a tabela guarda os 384 do all-MiniLM-L6-v2."
    },
    {
      "code": "try:\n    with psycopg.connect() as conn:\n        register_vector(conn)\n        conn.execute(\"UPDATE articles SET body = %s WHERE id = 'h15'\", (body,))\n        v = wl.embed([\"When your refund arrives. \" + body], norm=True)[0]\n        conn.execute(\"UPDATE articles SET embedding = %s WHERE id = 'h15'\", (v,))\nexcept psycopg.Error as e:\n    print(type(e).__name__ + \":\", e)",
      "note": "As duas atualizações rodam numa só transação, a que o bloco `with` abre, e um erro dentro do bloco desfaz a transação inteira. O `except` imprime o erro em vez de um traceback."
    },
    {
      "code": "with psycopg.connect() as conn:\n    print(conn.execute(\"SELECT left(body, 49) FROM articles WHERE id = 'h15'\").fetchone()[0])",
      "note": "Leia o artigo de volta numa conexão nova."
    }
  ],
  "output": "ana@lab:~/emb$ python edit.py\nDataException: expected 384 dimensions, not 256\nWe refund within three working days of the return"
}
```

**O vetor foi recusado, e o texto novo foi junto.** O artigo ainda diz *three working days* ("três
dias úteis"), o texto antigo, porque os dois `UPDATE`s estavam na mesma transação e o PostgreSQL
desfez a transação inteira. Nada em lugar nenhum guarda agora um texto cujo vetor descreve outra
coisa. Com os vetores num banco separado, o texto teria sido salvo, a gravação do vetor teria falhado,
e a busca continuaria ordenando o artigo pelo que ele dizia antes, sem nada que mostrasse isso.

## O que mais vem de graça

Os outros argumentos têm o mesmo formato: coisas que você já tem para o resto dos dados, e que um
segundo sistema precisaria de novo.

Os joins vêm primeiro. `recall.sql` avaliou 24 perguntas contra 40 artigos num comando só, e a mesma
busca pode se juntar a pedidos, estoque ou permissões sem que a aplicação costure duas respostas.
Depois vêm os backups: o `pg_dump`, e o que mais fizer backup do banco, já inclui a coluna de vetores,
e uma restauração traz de volta os textos e seus vetores do mesmo instante. **O controle de acesso se
aplica à busca como a qualquer outra consulta**, então a segurança em nível de linha que o Supabase
recomenda e a aula 17 constrói não precisa de uma segunda implementação. E há uma coisa só para
operar: um conjunto de credenciais, um calendário de atualizações, um lugar para olhar quando a
busca está lenta.

## Quando deixa de valer

Nada disso sai de graça em qualquer tamanho. O índice tem de morar em algum lugar, e no PostgreSQL
ele mora na mesma máquina que os pedidos.

**A busca disputa recursos com todo o resto.** A construção do HNSW nesta aula levou `8262.853 ms`
para 20.000 linhas, e toda consulta lê o grafo. Num banco que também recebe pagamentos, uma carga
vetorial pesada é carga sobre os pagamentos. Réplicas de leitura ajudam nas consultas; não ajudam na
construção.

**A extensão define os recursos.** A 0.6.0 do laboratório não tem vetores de meia precisão nem
varreduras iterativas de índice, e um provedor hospedado escolhe qual pgvector oferece. Um banco
dedicado pode ter quantização, índices filtráveis, busca híbrida por palavra-chave e vetor ou uma
coleção por cliente já prontos, onde o PostgreSQL os tem mais tarde ou à custa de mais SQL. As aulas
12, 13 e 17 mostram como eles são.

**O tamanho passa do que cabe numa máquina.** Um banco de vetores feito para fragmentar espalha uma
coleção por muitas máquinas como coisa normal. O PostgreSQL pode ser levado a fazer isso, com mais
trabalho.

A decisão para os 40 artigos da Marginalia não é apertada: um banco só. A decisão para um acervo que
é uma fatia grande do tamanho do banco inteiro, buscado com muito mais frequência do que qualquer
outra coisa é consultada, vale ser tomada de novo com uma medição. A aula 18 põe números no lado do
armazenamento dessa decisão.
