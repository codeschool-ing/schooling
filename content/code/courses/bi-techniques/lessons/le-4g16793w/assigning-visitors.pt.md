---
title: Sortear visitantes, e mantê-los sorteados
version: 1
---

**A aleatorização precisa de duas propriedades, e a implementação óbvia tem só uma.** Jogar uma
moeda a cada página vista é aleatório. Não é **fixo**: o mesmo visitante vê o checkout antigo na
segunda e o novo na terça, pertence aos dois grupos e torna a comparação sem sentido.

A implementação de sempre é um hash. Pegue o identificador do visitante e o nome do teste, passe
os dois por uma função de hash, e use o resultado para escolher o grupo:

```schooling-example
{"language": "python", "file": "assign.py", "parts": [{"code": "import hashlib\n\n\ndef group(visitor, test=\"checkout-2025-03\"):\n    digest = hashlib.sha256(f\"{test}:{visitor}\".encode()).hexdigest()\n    return \"new\" if int(digest[:8], 16) % 2 == 0 else \"old\"", "note": "O identificador do visitante e o nome do teste passam por um hash, uma função que transforma qualquer texto num número que parece aleatório e é sempre o mesmo para o mesmo texto. Números pares ficam com a página nova."}, {"code": "for visitor in [\"v000001\", \"v000002\", \"v000003\", \"v000004\", \"v000001\"]:\n    print(visitor, group(visitor))", "note": "Quatro visitantes, e o primeiro de novo: o mesmo visitante recebe o mesmo grupo toda vez."}, {"code": "print(\"\\nthe same visitors in another test:\")\nfor visitor in [\"v000001\", \"v000002\", \"v000003\", \"v000004\"]:\n    print(visitor, group(visitor, test=\"menu-2025-04\"))", "note": "Um nome de teste diferente reembaralha todo mundo, então estar no tratamento de um teste não diz nada sobre o próximo."}, {"code": "counts = {\"new\": 0, \"old\": 0}\nfor n in range(1, 100001):\n    counts[group(f\"v{n:06d}\")] += 1\nprint(f\"\\n100,000 visitors: {counts}\")", "note": "Com muitos visitantes a divisão sai perto de metade e metade, como uma moeda daria."}], "output": "v000001 old\nv000002 old\nv000003 new\nv000004 new\nv000001 old\n\nthe same visitors in another test:\nv000001 new\nv000002 old\nv000003 old\nv000004 old\n\n100,000 visitors: {'new': 50099, 'old': 49901}"}
```

Cada propriedade aparece na saída. O primeiro visitante aparece duas vezes e recebe o mesmo grupo nas
duas, então **o sorteio é fixo** sem guardar nada. Um nome de teste diferente dá outro embaralhamento,
então **os testes são independentes entre si**: estar no tratamento do teste de checkout não deixa um
visitante mais propenso a estar no tratamento do teste de cardápio. E em cem mil visitantes a divisão
sai 50.099 contra 49.901, que é o que uma moeda honesta produz.

## A unidade decide o que é "o mesmo visitante"

O hash só é tão fixo quanto o identificador que recebe. Um cookie identifica um navegador, então a
mesma pessoa no celular e no notebook são dois visitantes, e cada aparelho pode cair num grupo
diferente. Uma conta identifica uma pessoa, mas só depois que ela entra, e o teste de checkout da
Panela é sobre pessoas que ainda não fizeram pedido. **A unidade de aleatorização é uma escolha com
consequências**: a aula 7 disse que a métrica tem de ser contada na mesma unidade, e a seção depois da
próxima diz o que dá errado quando a unidade é menor que a pessoa.
