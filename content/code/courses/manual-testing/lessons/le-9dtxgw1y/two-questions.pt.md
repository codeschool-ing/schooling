---
title: Duas perguntas sobre um programa
version: 1
---

Verificação e validação costumam ser usadas como duas palavras para uma coisa só, conferir, e uma
delas é escolhida porque soa mais formal. São duas perguntas diferentes, e a diferença decide quem
pode responder cada uma. **A verificação pergunta se o produto corresponde ao que foi especificado:
estamos construindo certo? A validação pergunta se o que foi especificado é o que as pessoas que
vão usá-lo precisam: estamos construindo a coisa certa?** Barry Boehm formulou as duas assim em
1979, e as duas perguntas curtas sobreviveram à maior parte do que se escreveu em volta delas.

A ISO 9000 diz o mesmo com mais palavras. Verificação é a confirmação, com evidência objetiva, de
que *requisitos especificados* foram atendidos; validação é a mesma confirmação para *os
requisitos de um uso pretendido*. A primeira expressão aponta para um documento. A segunda aponta
para uma pessoa fazendo alguma coisa.

## Com o que cada uma compara

Todo teste compara o produto com alguma coisa. O que muda entre as duas é essa coisa.

A verificação compara o boxoffice com R1 a R9. A pergunta tem resposta no papel: o R5 dá 10% de
desconto ao membro, então um membro que reserva dois ingressos de Hamlet, a R$ 80,00 cada,
deve pagar R$ 144,00. Com o boxoffice rodando, num segundo terminal:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A2 msg
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
```

No navegador é a página Book com o endereço do membro, Hamlet e 2 no campo de ingressos, e a
página do pedido que vem em seguida diz o mesmo: 10% de desconto, R$ 144,00. **Isso é uma
verificação**, e a marca dela é que alguém que nunca viu a gerente do teatro poderia rodá-la e
decidir o resultado, porque tudo o que a decisão precisa está escrito.

A validação compara o boxoffice com algo que não está escrito por inteiro: o que o teatro e seu
público precisam. Será que 10% é o desconto que transforma um visitante ocasional em membro? O
membro vê o desconto antes de decidir comprar, ou só depois, na página do pedido? Nada em R1 a
R9 responde a nenhuma das duas, e um testador não consegue respondê-las sozinho. **A validação
precisa das pessoas que têm a necessidade**, ou de evidências do que elas fazem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" data-fig=\"l06-two-questions\" aria-label=\"Três caixas em fila: a necessidade, isto é, o teatro, sua equipe e seu público; os requisitos, R1 a R9; e o produto, boxoffice 1.0. Os requisitos são escritos a partir da necessidade e o produto é construído a partir dos requisitos. Uma revisão confere os requisitos e não roda nada. A verificação compara o produto com os requisitos e pergunta se ele está construído certo. A validação compara o produto com a necessidade e pergunta se ele é a coisa certa.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"90.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a necessidade</text><text x=\"110.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o teatro, sua equipe,</text><text x=\"110.0\" y=\"119.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seu público</text><rect x=\"260.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"97.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">os requisitos</text><text x=\"350.0\" y=\"112.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">R1 a R9</text><rect x=\"500.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"97.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o produto</text><text x=\"590.0\" y=\"112.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">boxoffice 1.0</text><path d=\"M204.0 105.0 L256.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"230.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dá origem</text><path d=\"M444.0 105.0 L496.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"470.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dão origem</text><path d=\"M310.0 66 C310.0 26 390.0 26 390.0 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"350.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">revisão: nada roda</text><path d=\"M590.0 144 L590.0 170 L350.0 170 L350.0 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"470.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">verificação: estamos construindo certo?</text><path d=\"M620.0 144 L620.0 220 L110.0 220 L110.0 144\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"365.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">validação: estamos construindo a coisa certa?</text></svg>", "caption": "O que cada atividade compara. A verificação e a revisão nunca saem dos requisitos escritos; a validação é a única que passa por eles e chega à necessidade.", "same": ["boxoffice 1.0"]}
```

## As duas podem discordar

Os casos que valem uma aula são aqueles em que só uma das duas passa.

Um produto pode **passar na verificação e falhar na validação**. O boxoffice recusa uma escola que
quer trinta lugares para The Little Prince, exatamente como o R4 manda, e a escola leva os alunos
para outro teatro. Todos os casos passam e o teatro perde o maior público do seu domingo. A seção
04 desta aula faz essa reserva.

Um produto pode **falhar na verificação e passar na validação**. Um desenvolvedor se afasta de um
requisito porque o requisito estava errado, os usuários ficam mais satisfeitos, e o requisito
continua dizendo a coisa antiga. Isso também é um achado, porque o próximo testador que ler R1 a R9
vai relatar o mesmo desvio como defeito, e a seção 05 diz o que fazer com ele.

## Quem responde a qual

| | verificação | validação |
|---|---|---|
| pergunta | estamos construindo certo? | estamos construindo a coisa certa? |
| compara o produto com | a especificação: R1 a R9 | a necessidade: o teatro, sua equipe, seu público |
| quem pode decidir o resultado | qualquer pessoa com a especificação na mão | as pessoas que têm a necessidade |
| uma falha é | um defeito no produto | um requisito errado, ou um que ninguém escreveu |
| feita com | revisões, casos de teste, as técnicas das aulas 2 a 5 | conversas guiadas, protótipos, aceite, observar pessoas usando |

A maior parte do dia de um testador está na coluna da esquerda, e é assim que deve ser: um
requisito escrito é a única coisa contra a qual duas pessoas conseguem combinar de testar. A coluna
da direita é onde o testador acrescenta algo que ninguém mais no time está em posição de
acrescentar, porque ele é a pessoa que acabou de usar o produto do jeito que um cliente usaria.

## Onde elas ficam num projeto

A aula 9 de `qa-fundamentals` desenha o modelo V, em que cada nível de especificação à esquerda tem
à direita um nível de teste que o espelha. Lido com estas duas palavras, cada par de lados opostos
do V é uma verificação: um nível de teste confere o produto contra o documento à sua frente. A
pergunta que o V não consegue fazer a si mesmo é se o documento do topo estava certo, e o nível
mais próximo dessa pergunta é o teste de aceitação, no alto à direita, que é a aula 12.

**Nenhuma das duas é uma fase que vem depois da codificação.** A verificação começa antes de
existir código, conferindo documentos uns contra os outros e contra si mesmos, e esse é o assunto
da próxima seção. A validação também começa antes de existir código, no dia em que alguém mostra à
gerente do teatro um rascunho da página de reserva e pergunta se é assim que a bilheteria funciona.
