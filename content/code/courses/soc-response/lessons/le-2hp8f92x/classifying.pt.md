---
title: Classificar: tipo e severidade
version: 1
---

Um incidente declarado recebe dois rótulos: **de que tipo** ele é, e **quão grave**. O tipo decide qual
playbook se aplica; a gravidade decide quem é avisado e com que rapidez. Os dois são provisórios e os dois são
revistos conforme a investigação aprende mais.

O **tipo** vem de uma lista fixa que a organização escolhe, para que incidentes possam ser contados e
comparados. Uma lista inspirada nas taxonomias comuns de compartilhamento tem itens como *acesso não
autorizado*, *código malicioso*, *disponibilidade*, *exposição de informação*, *fraude* e *uso indevido*. A
quinta é **acesso não autorizado** (credenciais de outra pessoa, vindo de fora) **com provável exposição de
informação** (a transferência para `203.0.113.200`).

A **gravidade** é mais fácil de combinar quando é dividida em perguntas separadas, como a orientação do NIST
fazia com três categorias de impacto:

| categoria | a escala | a quinta |
|---|---|---|
| **impacto funcional**: o que parou de funcionar? | nenhum, baixo, médio, alto | **nenhum**: todo serviço continuou rodando |
| **impacto na informação**: o que aconteceu com os dados? | nenhum, violação de privacidade, violação de informação proprietária, perda de integridade | **violação de privacidade**: o `files` guarda os arquivos fiscais dos clientes, que são dados pessoais |
| **recuperabilidade**: o que a recuperação exige? | regular, com reforço, estendida, irrecuperável | **irrecuperável** para o que saiu: uma cópia lá fora não pode ser chamada de volta |

Uma equipe que só perguntasse "quão grave é?" talvez respondesse *baixo*: nada caiu e ninguém percebeu. A
divisão mostra por que isso está errado. **Um incidente pode ser silencioso e grave ao mesmo tempo**, e a
linha da informação é a que traz o advogado e o encarregado de dados, hoje.
