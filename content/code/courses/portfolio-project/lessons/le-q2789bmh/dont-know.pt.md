---
title: A pergunta que você não sabe responder
version: 1
---

Alguma pergunta vai passar do que você sabe. *Como você lidaria com mil requisições por segundo?* *Que nível de
isolamento o SQLite usa?* Para um júnior isso é esperado, e quem entrevista muitas vezes pergunta justamente
para encontrar o limite. O que está sendo observado é o que você faz quando chega nele.

**Diga que não sabe, com todas as letras.** *Não sei* são duas palavras e não custam nada. Um chute confiante
custa muito, porque quem entrevista em geral sabe, e uma resposta errada dita com certeza diz que você vai
fazer o mesmo com um sistema em produção.

**Depois diga como descobriria**, o que transforma o limite em evidência. *Não sei de cabeça o nível de
isolamento do SQLite. Eu conferiria a documentação, e depois testaria: duas conexões, uma escrevendo dentro
de uma transação, e ver o que a outra lê.* Essa resposta mostra o que uma equipe mais precisa de um júnior,
que não é saber tudo, mas saber aprender com segurança.

**E, onde ajudar, raciocine em voz alta a partir do que você sabe.** *Sei que o SQLite deixa uma escrita acontecer
por vez e confere o índice único em cada uma, então para essa regra eu não dependo do nível de
isolamento.* Conhecimento parcial, apresentado como parcial, vale mais do que um chute e
mais do que silêncio.
