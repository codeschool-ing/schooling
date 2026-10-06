---
title: O risco precisa das três
version: 1
---

A consequência mais útil da cadeia da seção anterior é a que as pessoas pulam: **se qualquer elo
faltar, o risco por aquele caminho é zero.** Escrito assim parece óbvio, e na prática é ignorado
todo dia, nos dois sentidos.

| situação | ameaça | vulnerabilidade | ativo | risco por este caminho |
|---|---|---|---|---|
| o portal tem senha padrão e está na internet | sim | sim | sim | real |
| o mesmo portal só é alcançável de dentro do escritório | muito menos gente | sim | sim | menor |
| o portal tinha senha padrão e nada atrás dela | sim | sim | não | nenhum |
| o portal tem senha forte e única e MFA | sim | não esta | sim | nenhum por este caminho |

A segunda linha é onde mora a maioria das decisões de segurança. Pôr o portal atrás da rede do
escritório não consertou a senha. Diminuiu o número de pessoas que podiam tentá-la, o que diminuiu
a **probabilidade**. As aulas 4 e 5 constroem arquiteturas inteiras com essa ideia.

A terceira linha é a que as pessoas esquecem quando um scanner aponta uma vulnerabilidade. Um
servidor com um programa antigo e vulnerável instalado não é urgente se o servidor não guarda nada,
não alcança nada e vai ser desligado. **Uma vulnerabilidade sem um ativo atrás é um achado, não um
risco.** Ela ainda é corrigida, porque servidores têm o costume de ganhar ativos depois, mas não
fura a fila.

### Probabilidade e impacto

Como o risco depende de uma ameaça acontecer de fato e do tamanho do estrago, ele em geral é
expresso com dois fatores:

> **risco = probabilidade × impacto**

**Probabilidade** é quão provável é que uma ameaça explore uma vulnerabilidade num certo período.
**Impacto** é quanto dano resulta se isso acontecer. A multiplicação nem sempre é literal; a aula
3 mostra uma versão qualitativa, com palavras no lugar de números, e uma quantitativa, com
dinheiro. O que a fórmula diz em todas as versões é que **os dois fatores contam**: um evento
provável de impacto trivial e um evento improvável de impacto catastrófico podem merecer a mesma
atenção.

A ISO 31000, a norma geral de gestão de riscos, define risco de forma mais abstrata, como "o efeito
da incerteza sobre os objetivos". As duas definições não competem. A da ISO explica por que o risco
existe: você não sabe o que vai acontecer. A de probabilidade e impacto é como você o mede na
prática. O guia de avaliação de risco do NIST, o SP 800-30, trabalha com a segunda.
