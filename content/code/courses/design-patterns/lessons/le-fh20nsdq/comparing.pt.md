---
title: Os quatro lado a lado
version: 1
---

**Os três padrões concordam sobre o modelo e discordam sobre a view, e o jeito mais rápido de
distingui-los é perguntar quem guarda referência a quem.** Nomes não são confiáveis, como as
"views" do Django mostraram na seção sobre o servidor; setas são. Esta seção põe os quatro programas
da lição um ao lado do outro e os lê desse jeito.

Comece pelo que não mudou. Todo programa importou o mesmo modelo, e o modelo nunca imprimiu nada:

```
ana@laptop:~/patterns/presentation$ grep -n "^from desk_model" *.py
mvc.py:4:from desk_model import Desk
mvp.py:4:from desk_model import Desk
mvvm.py:3:from desk_model import Desk
test_presenter.py:4:from desk_model import Desk
web.py:5:from desk_model import Desk
ana@laptop:~/patterns/presentation$ grep -c "print" desk_model.py
0
```

Quatro apresentações e um teste, sobre um modelo, que o `grep -c` confirma não ter `print` nenhum.
**Essa é a separação de que a lição inteira trata, e é a parte que vale a pena manter mesmo quando
você não usa nenhum dos padrões pelo nome.** O laço emaranhado da primeira seção não poderia ter
sido compartilhado por um terminal, uma página web, um teste e um conjunto de widgets;
`desk_model.py` foi.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l07-triads\" aria-label=\"Três painéis, um por padrão, cada um mostrando que parte guarda referência a qual. MVC: o controlador chama o modelo, o modelo notifica a view, e a view lê o modelo; o modelo não aponta para ninguém. MVP: a view repassa eventos ao presenter, o presenter chama o modelo e diz à view o que mostrar; a view nunca vê o modelo. MVVM: a view se liga ao view-model, o view-model chama o modelo e é notificado por ele; o view-model nunca vê a view.\"><defs><marker id=\"l07-triads-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">MVC</text><rect x=\"63.0\" y=\"55.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Model</text><rect x=\"6.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">View</text><rect x=\"120.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Controller</text><path d=\"M172.0 185.0 L140.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"160.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama</text><path d=\"M88.0 89.0 L40.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"8.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notifica</text><path d=\"M80.0 185.0 L112.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"102.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê</text><text x=\"115.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">o modelo não aponta para ninguém</text><path d=\"M240.0 30.0 L240.0 285.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">MVP</text><rect x=\"308.0\" y=\"45.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Model</text><rect x=\"308.0\" y=\"115.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Presenter</text><rect x=\"308.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">View</text><path d=\"M360.0 115.0 L360.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"367.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama</text><path d=\"M345.0 185.0 L345.0 147.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"285.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eventos</text><path d=\"M375.0 147.0 L375.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"383.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">show_…</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a view nunca vê o modelo</text><path d=\"M485.0 30.0 L485.0 285.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"605.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">MVVM</text><rect x=\"553.0\" y=\"45.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Model</text><rect x=\"553.0\" y=\"115.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ViewModel</text><rect x=\"553.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">View</text><path d=\"M590.0 115.0 L590.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"536.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama</text><path d=\"M620.0 77.0 L620.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"628.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notifica</text><path d=\"M605.0 185.0 L605.0 147.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"612.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">liga-se</text><text x=\"605.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">o view-model nunca vê a view</text></svg>", "caption": "Quem guarda referência a quem. Nos três o modelo não aponta para ninguém; o que muda é a linha entre a view e o resto.", "same": ["MVC", "MVP", "MVVM", "show_…"]}
```

## A tabela

| | MVC (desktop) | MVC (web) | MVP | MVVM |
|---|---|---|---|---|
| a entrada chega | ao controller | ao controller, por uma rota | à view, que a repassa ao presenter | à view, por bindings e comandos |
| a view vê o modelo? | sim, ela o lê | não, ela recebe valores | não | não, ela vê o view-model |
| quem atualiza a tela | a view, quando o modelo a avisa | o controller, renderizando uma view por requisição | o presenter, chamando a view | os bindings, quando uma propriedade muda |
| a lógica de tela mora | na view | no controller e no template | no presenter | no view-model |
| o que um teste alcança sem tela | o modelo | o controller e o template, como funções | o presenter, com uma view falsa | o view-model, direto |
| em `~/patterns/presentation` | `mvc.py` | `web.py` | `mvp.py` | `mvvm.py` |

A linha que decide a maioria das escolhas é a quarta. **Lógica de tela é tudo o que decide o que a
pessoa vê sem ser uma regra da biblioteca**: que o `B1` está cinza, que 150 centavos se leem
`R$ 1,50`, que uma recusa é um alarme. Ela existe em todo programa com tela. Os padrões diferem em
onde a põem, e o lugar onde a põem é exatamente o que um teste alcança ou não alcança.

## O que cada um custa, medido

Os quatro arquivos de apresentação não têm o mesmo tamanho, e as diferenças são honestas:

```
ana@laptop:~/patterns/presentation$ wc -l mvc.py web.py mvp.py mvvm.py
  47 mvc.py
  67 web.py
  65 mvp.py
 102 mvvm.py
 281 total
```

`mvvm.py` é o mais longo porque carrega a própria maquinaria de binding, o `Observable` e três
widgets substitutos; no WPF, no Vue ou no Android isso vem com o framework, e o view-model sozinho
fica mais ou menos do tamanho do presenter. `mvp.py` paga pela interface da view, dois métodos aqui
e muitos mais num formulário de verdade. `web.py` gasta as linhas a mais com HTTP: decodificar o
formulário e escolher um status. Nada disso é custo do modelo, que foi pago uma vez só.

## As duas perguntas que os distinguem

Diante de um código desconhecido, duas perguntas o situam mais depressa que os nomes das pastas.

**A view guarda referência ao modelo?** Se guarda, e se redesenha quando o modelo anuncia uma
mudança, você está olhando para o MVC original. Se recebe valores e os renderiza uma vez, é o MVC da
web.

**Se não, alguma coisa chama a view, ou a view se inscreve?** Uma classe que chama `view.show_…` é um
presenter. Uma classe que expõe propriedades e nunca ouviu falar da view é um view-model.

A lição 19 volta a reconhecer padrões pela forma em código que você não escreveu; este é um dos
casos em que a forma é fácil de ver quando você sabe qual seta procurar.
