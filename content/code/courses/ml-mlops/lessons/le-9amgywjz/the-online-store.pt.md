---
title: O armazenamento online, e valores velhos demais para servir
version: 1
---

O armazenamento online responde uma pergunta, **como está este membro agora?**, e é montado a partir
do offline em vez de calculado à parte, para que os dois nunca discordem sobre o que um atributo
significa. Cada membro recebe a sua linha mais nova. A decisão é o que fazer quando essa linha é
velha.

```
ana@dev:~/ml$ python featurestore.py online
online store: 3372 members as of 2026-02-28; 466 left out as too old to serve
ana@dev:~/ml$ python featurestore.py get 2
{'member_id': 2, 'as_of': '2026-02-28', 'channel': 'store', 'age_band': '25-34', 'home_shop': 'Savassi', 'tenure_days': 468.0, 'recency_days': 3.0, 'visits_180d': 4, 'spend_180d': 30940, 'basket_avg': 7735.0, 'online_share': 0.25, 'shops_180d': 2}
ana@dev:~/ml$ python featurestore.py get 8
None
```

O armazenamento offline conhece 3.838 membros, todo mundo que esteve ativo em algum domingo desde
junho. **466 deles não têm linha dos últimos sete dias**: deixaram de estar ativos, e os seus valores
mais novos têm semanas ou meses. Servidos, eles descreveriam um membro que não existe mais, como se
tivesse visitado ontem. Então o `online` os deixa de fora, e pedir um, como o último comando faz com
o membro 8, devolve `None`.

Os 3.372 mantidos são os 3.355 de hoje e **17 membros cuja linha mais nova é a do domingo passado**:
ativos em 22 de fevereiro, não mais ativos em 28 de fevereiro, e ainda dentro dos sete dias. Eles são
servidos com uma linha de seis dias atrás. Esse é o tempo de vida fazendo o que diz, e é uma escolha:
um mais curto os descartaria e um mais longo manteria mais dos 466.

**O que um serviço faz com `None` é decisão da plataforma, tomada antes.** Recusar a pontuação,
pontuar com valores padrão ou cair para uma regra: cada uma é defensável, e cada uma precisa estar
escrita, porque a alternativa é um serviço que quebra no primeiro membro que o armazenamento
esqueceu. O serviço da lição 8 precisa escolher.
