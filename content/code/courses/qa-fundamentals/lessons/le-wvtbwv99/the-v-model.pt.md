---
title: O modelo V
version: 1
---

**O modelo V pega as fases da cascata e as dobra ao meio.** O lado esquerdo desce, da descrição mais ampla
do sistema até o menor pedaço de código: requisitos, projeto do sistema, arquitetura, projeto do módulo. O
fundo do V é o código. O lado direito sobe de volta, testando em cada nível o que o nível correspondente da
esquerda descreveu: testes de unidade, de integração, de sistema, de aceitação.

O modelo nasceu da engenharia de sistemas nos anos 1980, na Alemanha e nos Estados Unidos, para grandes
projetos de governo, e ainda é o modelo de processo oficial do governo federal alemão, com o nome V-Modell
XT. É a cascata desenhada de modo que **toda especificação tenha um teste que a confere**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 300\" role=\"img\" data-fig=\"l09-v\" aria-label=\"Uma forma de V. O braço esquerdo desce por requisitos, projeto do sistema, arquitetura e projeto do módulo até o código, embaixo. O braço direito sobe por teste de unidade, teste de integração, teste de sistema e teste de aceitação. Linhas horizontais tracejadas ligam cada nível da esquerda ao teste da direita que o confere: requisitos a teste de aceitação, projeto do sistema a teste de sistema, arquitetura a teste de integração, projeto do módulo a teste de unidade.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"qa-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"24.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requisitos</text><rect x=\"490.0\" y=\"24.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de aceitação</text><path d=\"M174.0 40.0 L486.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"330.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">testado contra</text><path d=\"M60.0 57.0 L80.0 79.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M580.0 79.0 L600.0 57.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><rect x=\"60.0\" y=\"80.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">projeto do sistema</text><rect x=\"450.0\" y=\"80.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de sistema</text><path d=\"M214.0 96.0 L446.0 96.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M100.0 113.0 L120.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M540.0 135.0 L560.0 113.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><rect x=\"100.0\" y=\"136.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">arquitetura</text><rect x=\"410.0\" y=\"136.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de integração</text><path d=\"M254.0 152.0 L406.0 152.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M140.0 169.0 L160.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M500.0 191.0 L520.0 169.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><rect x=\"140.0\" y=\"192.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">projeto do módulo</text><rect x=\"370.0\" y=\"192.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de unidade</text><path d=\"M294.0 208.0 L366.0 208.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"255.0\" y=\"248.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">código</text><path d=\"M220.0 225.0 L255.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M405.0 262.0 L440.0 225.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><text x=\"20.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">descrito, na descida</text><text x=\"640.0\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">testado, na subida</text></svg>", "caption": "Cada linha horizontal é um par: uma descrição, e o nível de teste cujos resultados esperados vêm dela. Os testes da direita podem ser projetados assim que a descrição da esquerda existe."}
```

## Cada nível, e contra o que é testado

As linhas horizontais que atravessam o V são o ponto do desenho. Cada uma junta uma descrição ao nível de
teste que confere o sistema contra ela:

| lado esquerdo: o que é descrito | lado direito: o que o testa | a pergunta que o teste responde |
|---|---|---|
| **requisitos**: do que os usuários precisam | **teste de aceitação** | é isto o que se queria? |
| **projeto do sistema**: o que o sistema faz como um todo | **teste de sistema** | o sistema inteiro faz o que foi especificado? |
| **arquitetura**: que partes existem e como conversam | **teste de integração** | as partes funcionam juntas? |
| **projeto do módulo**: o que cada pedaço faz | **teste de unidade** | cada pedaço faz o que deveria, sozinho? |

Cada nível de teste tem sua **base de teste**, o documento de onde vêm os resultados esperados. Um teste de
unidade é julgado contra o projeto do módulo; um teste de aceitação é julgado contra as necessidades dos
usuários. Um teste no nível errado responde à pergunta errada: testes de unidade que passam não dizem nada
sobre se a loja faz o que a Célia precisa.

## Teste projetado na descida

A ideia mais útil do V é sobre tempo. O lado direito é *executado* depois de o código existir, mas pode ser
*projetado* na descida, conforme cada documento da esquerda é escrito. Quando a Joana escreve a regra de
preço, os testes de aceitação dela podem ser escritos na mesma semana. Quando a arquitetura diz que o
`orders.py` chama o `tickets.py`, os testes de integração dessa chamada podem ser planejados antes de os dois
existirem.

Isso é shift left dentro de um processo sequencial. Não leva a execução dos testes para mais cedo, mas leva o
**pensamento** para mais cedo, e pensar em como testar um requisito é o momento em que ambiguidades como
*maiores de 60* aparecem. Quem projeta testes de aceitação enquanto o requisito ainda é rascunho está
fazendo prevenção, mesmo no projeto mais tradicional que existe.

## O que o V guarda da cascata

Guarda a sequência. O código ainda chega todo de uma vez, no fundo; os testes ainda rodam, nível a nível,
subindo o lado direito; um defeito achado no teste de aceitação ainda manda o time de volta ao canto
superior esquerdo, meses depois. O V melhora onde o teste é **projetado**, não onde ele **acontece**. Os
modelos das aulas seguintes atacam o segundo problema, tornando o V inteiro pequeno e rodando-o muitas vezes.
