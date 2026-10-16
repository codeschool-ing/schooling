---
title: Gastando bem um orçamento de otimização
version: 1
---

Uma busca custa ajustes, e ajustes custam tempo. Quase tudo o que torna a otimização eficiente é
decidir o que não testar.

**Saiba quais botões importam.** No gradient boosting importam mais a taxa de aprendizado, o tamanho de
cada árvore e o número de árvores, e eles interagem: uma taxa menor precisa de mais árvores. Ajustes de
regularização importam menos. Numa floresta aleatória, o `max_features` e o tamanho da folha importam,
e o número de árvores só precisa ser grande o bastante. Uma busca em botões que não mudam nada é uma
busca gasta em ruído.

**Deixe a parada antecipada definir o número de árvores.** A aula 8 mostrou que a parada antecipada
mede o número certo de árvores para uma dada taxa. Isso tira da busca o botão mais caro: fixe uma taxa
baixa, deixe a parada antecipada parar, e otimize o resto.

**Busque grosso, depois fino.** Uma primeira busca aleatória em faixas largas e escala logarítmica acha
a região; uma segunda, mais estreita, a refina. Gastar o orçamento inteiro de uma vez numa grade fina
sobre a região errada é a falha comum.

**Pare quando os ganhos estiverem dentro do ruído.** A dispersão entre partes no `baseline_cv.py` foi
de centenas de reais por mil linhas. Um ajuste que vence por vinte não venceu. A partir daí, o esforço
rende mais em outro lugar: as variáveis da aula 14 costumam mexer num modelo mais que os botões da aula
9.

**Não otimize no teste.** Vale dizer uma última vez, porque a otimização é onde isso mais acontece:
quem roda uma busca, olha o teste, ajusta as faixas e busca de novo fez do teste um conjunto de
validação, e o número que relata é o otimista.

**Anote o que foi testado.** As faixas, o número de candidatos, as partes, a nota, a semente. A aula 15
torna o pipeline inteiro reprodutível; um modelo otimizado cuja busca ninguém consegue repetir também
não pode ser conferido por ninguém.
