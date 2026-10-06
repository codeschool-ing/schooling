---
title: O laboratório, e o que nele é real
version: 1
---

Todas as transcrições deste curso foram gravadas numa única máquina Linux, e o curso traz o script
que a constrói: `lab.sh`, ao lado de `course.json`. É a máquina que o `embeddings-vectors` construiu,
com um cômodo a mais. `sudo bash lab.sh up` num Ubuntu 24.04 constrói primeiro o laboratório daquele
curso, o modelo de embeddings, o provedor de embeddings substituto e o PostgreSQL com pgvector, e
depois acrescenta o que este curso precisa por cima. `sudo bash lab.sh reset` devolve o diretório de
trabalho ao estado de antes da aula 1, e o `captures.sh` de cada aula começa por ele.

Quem está no teclado continua sendo a ana, desenvolvedora da Marginalia, a livraria online que não
existe. No `embeddings-vectors` ela buscava na central de ajuda da loja, quarenta artigos de quarenta
palavras cada. Este curso precisa de documentos que valha a pena recuperar, e isso é outra coisa.

## Os documentos

```
ana@lab:~/rag$ ls data
chat-a.jsonl
chat-b.jsonl
docs
eval.jsonl
help.jsonl
listings.jsonl
querylog.jsonl
ana@lab:~/rag$ wc -l data/*.jsonl
   12 data/chat-a.jsonl
    4 data/chat-b.jsonl
   30 data/eval.jsonl
   40 data/help.jsonl
    6 data/listings.jsonl
  500 data/querylog.jsonl
  592 total
```

`docs/` é o corpus: treze documentos do tipo que toda empresa tem e nenhum modelo leu.

```
ana@lab:~/rag$ ls data/docs
affiliate-api.md
ebooks-and-audiobooks.md
finance-refund-controls.md
gift-cards.md
payments-and-invoices.md
privacy-notice.md
returns-policy-2025.md
returns-policy.md
seller-agreement.md
shipping-and-delivery.md
support-handbook.md
terms-of-sale.md
warehouse-runbook.md
ana@lab:~/rag$ head -12 data/docs/returns-policy.md
---
id: returns-policy
title: Returns and refunds policy
audience: public
owner: customer-support
updated: 2026-02-02
version: 4
status: current
supersedes: returns-policy-2025
---

# Returns and refunds policy
ana@lab:~/rag$ wc -w data/docs/*.md | tail -1
 6843 total
ana@lab:~/rag$ grep -c "14 days" data/docs/*.md | grep -v ":0"
data/docs/ebooks-and-audiobooks.md:2
data/docs/returns-policy-2025.md:2
data/docs/returns-policy.md:5
data/docs/seller-agreement.md:2
```

Eles foram escritos para o curso com três propriedades contra as quais um sistema de recuperação
precisa ser testado. **São longos o bastante para serem cortados**: só o regulamento de devoluções já
é maior do que o modelo de embeddings consegue ler de uma vez, e a aula 4 mede isso. **São ambíguos
onde documentos reais são**: há dois regulamentos de devolução, o que está em vigor e o que ele
substituiu, e "14 days" aparece onze vezes em quatro documentos, para e-books, audiolivros, pacotes
danificados, títulos trocados, vendedores do marketplace e o antigo prazo de devolução. **São
estruturados**, com títulos e cláusulas numeradas, então uma citação pode apontar para algo menor que
um documento inteiro. Três deles são só para funcionários, e um só para a equipe financeira; a aula 14
trata de mantê-los assim.

Os arquivos `.jsonl` são o resto das peças do curso: `eval.jsonl` são trinta perguntas com os trechos
que as respondem, para a aula 8; as duas conversas são para as aulas de memória e de isolamento; os
anúncios e o registro de perguntas são para as aulas 16 e 17. `help.jsonl` é a central de ajuda do
`embeddings-vectors`, copiada como estava.

## O gerador, que não é um modelo

```
ana@lab:~/rag$ curl -s localhost:8600/; echo
{"labgen": "ok", "models": ["extract-1"]}
```

**Nenhum modelo de linguagem estava ao alcance da máquina em que este curso foi gravado**, e uma chave
de API é uma conta que um curso não pode distribuir. Por isso o laboratório roda o `labgen`, um
servidor que fala os formatos do Chat Completions da OpenAI e da Messages API da Anthropic bem o
bastante para que os SDKs Python das duas empresas, e os frameworks construídos sobre eles, conversem
com ele sem modificação. O único modelo que ele serve, o `extract-1`, não é um modelo de linguagem. Ele
não escreve nenhuma palavra nova: copia frases inteiras do texto que recebe, escolhidas por uma regra.
Suas quatro regras, na ordem em que ele as aplica:

| regra | o que o extract-1 faz |
| --- | --- |
| uma instrução | se algum texto que ele recebe diz *reply with the word X*, ele responde X |
| resumir | um pedido que começa com "Summarise" recebe as frases mais próximas do significado médio da conversa |
| fontes | com fontes no prompt, ele responde com até três frases delas mais parecidas com a pergunta, cada uma seguida do número da fonte |
| livro fechado | sem nada para ler, ele responde com a mais próxima de dez frases que o curso escreveu |

A similaridade da terceira regra é real: cada frase e a pergunta viram embeddings com o
all-MiniLM-L6-v2, o modelo que o `embeddings-vectors` rodou, e são comparadas pelo cosseno. Uma frase
precisa de similaridade de pelo menos 0,53 para ser usada; se nenhuma chega lá, a resposta é uma frase
dizendo que as fontes não respondem. A aula 7 diz de onde veio esse número.

Isso muda o que as aulas podem afirmar, e vale ser exato sobre isso. **O que é real é tudo em volta do
gerador**: os pedaços, os embeddings, as similaridades, o banco de dados, as contagens de tokens, os
SDKs e os frameworks, e cada número que eles imprimem. **O que é do laboratório é o texto de cada
resposta.** Quando uma aula mostra o extract-1 errando, o erro é um que um modelo real também comete,
mas um modelo real erra de forma menos mecânica e com menos frequência. Quando uma aula precisa falar
de como um modelo real se comporta, por exemplo com um contexto longo, ela diz isso e não finge que o
laboratório mediu.

## O que custa acompanhar

```
ana@lab:~/rag$ du -sh /opt/emb /opt/rag 2>/dev/null
1.4G	/opt/emb
516M	/opt/rag
```

O software dos dois cursos ocupa cerca de 2 GB: uma máquina Linux ou uma máquina virtual com espaço
para isso e para um banco de dados comum basta, e não é preciso conta em lugar nenhum.

Se você tiver sua própria chave de API, todos os programas deste curso rodam contra um provedor real
trocando duas variáveis de ambiente, `OPENAI_BASE_URL` e a chave, e o nome do modelo. As respostas
serão diferentes das impressas aqui; a recuperação não.
