---
title: O conjunto de teste
version: 2
---

Toda aula desde a quarta mediu alguma coisa contra o `data/eval.jsonl`, e cada medição foi só tão boa
quanto esse arquivo. Esta aula põe o arquivo no centro do pipeline: a coisa que diz se uma mudança
deixou o sistema melhor, antes de algum cliente descobrir.

## O que tem nele

```
ana@vm:~/rag$ head -n 3 data/eval.jsonl
{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": [["returns-policy", "The return window"]], "facts": ["30 days from delivery"]}
{"id": "e02", "question": "Who pays for the return postage?", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"]}
{"id": "e03", "question": "How long after my return arrives will I get the refund?", "gold": [["returns-policy", "Refunds"]], "facts": ["within three working days"]}
ana@vm:~/rag$ tail -n 2 data/eval.jsonl
{"id": "e29", "question": "Which carrier do you use in Portugal?", "gold": [], "facts": []}
{"id": "e30", "question": "Is there a student discount?", "gold": [], "facts": []}
```

Cada linha é uma pergunta como um cliente ou um atendente faria, os documentos e seções que a
respondem, e **fatos**: algumas palavras que o trecho que responde contém, exatamente. Trinta perguntas,
26 com resposta nos documentos e quatro sem nenhuma, que têm de ser recusadas. Todas foram escritas
para o curso, lendo os documentos e perguntando o que alguém ia querer deles.

Um fato é um instrumento propositalmente grosseiro. Funciona quando a resposta cita a fonte, e o
llama3.2:3b muitas vezes cita: *30 days from delivery* volta como foi escrito. Quando o modelo
parafraseia, *10 days* não bate com *waits there for ten days*, e a seção sobre juízes que são modelos
diz o que pode substituí-lo. Mesmo assim,
vale escrever um fato para cada pergunta: é o que transforma "a resposta parece certa" numa verificação
que um programa roda em todo commit.

## O que um bom conjunto de teste contém

**Perguntas que as pessoas fazem de verdade, nas palavras delas.** A melhor fonte é o registro de um
sistema já em uso, ou a caixa de entrada do atendimento antes de haver um. Perguntas escritas por quem
escreveu os documentos usam as palavras dos documentos e lisonjeiam qualquer busca.

**Perguntas sem resposta.** Um conjunto sem elas não consegue medir a recusa, e a aula 7 mostrou que é
na recusa que um pipeline falha de forma mais visível. Quatro é o mínimo para ver o comportamento; um
conjunto real quer um décimo ou mais.

**Cada tipo de pergunta que os usuários fazem.** A aula 6 precisou de um segundo arquivo, o
`identifiers.jsonl`, porque as perguntas de cliente não tinham códigos de erro. Um conjunto que só cobre
um tipo de pergunta só informa sobre esse tipo.

**Os casos difíceis**: dois documentos que discordam, uma pergunta cuja resposta está numa tabela, uma
pergunta que precisa de duas seções. É onde estão as falhas.

## Separando uma parte

A aula 7 escolheu um limiar olhando as trinta perguntas, e chamou o resultado de otimista: um número
ajustado a um conjunto sempre parece melhor nesse conjunto. A defesa é **separar uma parte do conjunto
de teste** e olhar para ela só para confirmar uma decisão já tomada. O `evaluate.py` separa uma a cada
três perguntas pelo id:

```
ana@vm:~/rag$ python -c "import json; qs = [json.loads(l) for l in open(\"data/eval.jsonl\")]; print(\" \".join(q[\"id\"] for q in qs if int(q[\"id\"][1:]) % 3 == 0))"
e03 e06 e09 e12 e15 e18 e21 e24 e27 e30
```

Dez separadas, duas delas sem resposta; vinte no conjunto de **desenvolvimento** (dev), usado em toda
comparação desta aula. A regra é a disciplina: experimente ideias no dev quantas vezes quiser, e rode o
separado uma vez, quando a decisão estiver tomada. Uma equipe que ajusta no separado não tem separado.

Trinta perguntas é pouco. Cada uma vale três ou quatro pontos percentuais de qualquer nota, e a aula 4
já avisou para não ler muito na diferença de uma pergunta. Um sistema real faz o conjunto crescer a
partir dos registros, algumas perguntas por semana, cada uma um caso que já deu errado uma vez.
