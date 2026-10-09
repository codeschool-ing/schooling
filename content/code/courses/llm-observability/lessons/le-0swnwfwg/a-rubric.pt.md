---
title: Uma rubrica, e duas pessoas lendo
version: 2
---

Uma **rubrica** é o que se diz a quem avalia: o critério, os veredictos possíveis, e o que decide entre
eles. O juiz recebe uma no prompt de sistema, no `judge.py`. As pessoas precisam de uma pelo mesmo
motivo, e a primeira versão que a equipe escreveu para relevância é a frase do juiz, arrumada para uma
pessoa. Salve-a, e a versão seguinte, em `data/rubrics`:

```sh
mkdir -p data/rubrics
cat > data/rubrics/relevance-v1.md <<'EOF'
# Relevance, version 1

Read the customer's question and the assistant's reply.

Does the reply address the question the customer asked?

- pass: it does
- fail: it does not
EOF
```

Duas escolhas nela são de propósito, e as duas são o conselho de costume para uma primeira rubrica.

**Aprovado ou reprovado, não uma nota de 1 a 5.** Uma escala pede a quem avalia que ponha uma resposta
numa linha, e duas pessoas põem a mesma resposta a um ponto de distância sem discordar de nada: uma dá 4
a tudo o que é bom e a outra guarda o 5 para o excepcional. Cada degrau de uma escala precisa da
própria descrição para significar o mesmo para todos, e uma equipe escrevendo a primeira rubrica ainda
não sabe quais são os degraus. Um veredicto binário faz uma pergunta só, e uma discordância nele é uma
discordância de verdade.

**Um critério.** Só relevância, não relevância, fidelidade e tom num veredicto só. Uma pessoa avaliando
três coisas ao mesmo tempo avalia a que notou primeiro, e uma reprovação não consegue dizer qual das
três falhou.

## Os rótulos

A Ana e o Bruno leram cada um as quarenta e oito respostas, com as perguntas e as fontes, e escreveram
um veredicto para cada uma contra a versão 1, e depois contra a versão 2. Cada linha do
`data/labels.jsonl` nomeia uma resposta pelo id da pergunta e pela versão que respondeu, e leva todos os
veredictos escritos sobre ela, sob a rubrica contra a qual foram escritos. Salve-o:

```json
{"case": "e01", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e02", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e03", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e04", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e05", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e06", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e07", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e08", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e09", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e10", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e11", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e12", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "fail", "agreed": "fail"}}
{"case": "e13", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e14", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e15", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e16", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e17", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e18", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e19", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e20", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e21", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e22", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e23", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e24", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e01", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e02", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e03", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e04", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e05", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e06", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e07", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e08", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e09", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e10", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e11", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e12", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "fail", "agreed": "fail"}}
{"case": "e13", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e14", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e15", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e16", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e17", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e18", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e19", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "fail", "agreed": "fail"}}
{"case": "e20", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e21", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e22", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e23", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e24", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
```

Quarenta e oito linhas, cinco veredictos em cada: os da Ana e do Bruno contra a versão 1, os mesmos dois
contra a versão 2, e o veredicto que acordaram depois de conversar, ao qual as próximas seções chegam.

As respostas são as do conjunto de avaliação, rodado de novo pelo `evalrun.py` da aula 8, uma vez como
cada versão:

```
ana@dev:~/obs$ python evalrun.py old --release 2026.09.4
runs/old.jsonl: 24 questions, release 2026.09.4
ana@dev:~/obs$ python evalrun.py new --release 2026.10.1
runs/new.jsonl: 24 questions, release 2026.10.1
```

A versão da rubrica está em todo rótulo, e isso importa tanto quanto o id da resposta. Um rótulo
escrito contra a versão 1 diz o que alguém achou que a versão 1 queria dizer; misturá-lo com rótulos
escritos contra uma versão com outras instruções não mede nada.
