---
title: Quando os documentos mudam
version: 2
---

Uma resposta em cache é uma cópia do que o pipeline disse sobre os documentos como eles eram. Quando um
documento muda, a cópia fica desatualizada, e um cache sem jeito de perceber serve a política antiga com a
mesma confiança da nova. A aula 3 argumentou que um sistema de RAG fica atualizado no momento em que o
índice fica; um cache na frente dele só fica atualizado se souber quando o índice mudou.

A chave do cache exato leva a versão do índice, um hash de todos os ids de pedaço. Aqui está a versão,
depois uma edição nos termos do cartão-presente e o carregador da aula 5, depois a versão de novo:

```
ana@vm:~/rag$ python -c "import exact; print(exact.version())"
0acfdfa0d064
ana@vm:~/rag$ sed -i "s/valid for two years from the day it was bought/valid for three years from the day it was bought/" data/docs/gift-cards.md && python ingest.py
chunks: 137  embedded: 1  removed: 1  kept: 136
ana@vm:~/rag$ python -c "import exact; print(exact.version())"
de4849f90b4a
```

**Um pedaço com embedding refeito, um removido, e uma versão nova.** Toda chave montada com a versão
antiga agora falha, então a primeira pergunta depois da mudança vai para o pipeline, que lê o texto novo.
Nada precisou achar as respostas sobre cartão-presente no cache; elas simplesmente deixaram de casar.

O custo é que uma edição num documento faz falhar toda resposta em cache, inclusive as que não tinham nada
a ver com cartões-presente. Uma chave mais fina, as versões só dos documentos que uma resposta citou,
mantém as respostas sem relação, ao preço de guardar quais documentos cada resposta usou, o que o
registro da aula 9 já guarda. Para um acervo que muda toda semana, a versão grossa é mais simples e as
falhas saem baratas; para um que muda a cada minuto, a mais fina se paga.

A exclusão é o caso que não pode esperar. Um documento retirado por estar errado, ou removido a pedido de
alguém, precisa sair do cache no momento em que sai do índice, o que uma versão na chave garante e um
prazo de validade não.
