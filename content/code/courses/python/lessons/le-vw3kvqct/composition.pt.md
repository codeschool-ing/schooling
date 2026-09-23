---
title: Ter um, em vez de ser um
version: 2
---

```python
class Notifier:
    def __init__(self, transport):
        self.transport = transport      # it HAS one

    def notify(self, message):
        self.transport.deliver(format(message))
```

Composição é um objeto guardando outro objeto e chamando-o. Sem herança, sem classe base, e sem
maquinaria compartilhada sobre a qual os dois tenham de concordar.

## A pergunta que decide

**Isto é um TIPO daquilo, ou ele TEM um?**

Um `Student` é uma `Person` — herança. Um `Notifier` tem um transporte — composição. Dita em voz
alta, a resposta costuma ser óbvia, e o motivo de as pessoas irem à herança mesmo assim é que ela é
ensinada primeiro e parece reaproveitamento.

## O que dá errado com a escolha errada

O requisito que chega nunca é "mais um tipo". É "o de SMS deveria repetir a tentativa, o de log
não". Repetir não é um tipo de notificação — é algo que acontece em volta de uma. Com herança isso
vai para a classe base atrás de uma bandeira, e a base agora conhece uma subclasse que ela não
deveria conhecer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Com herança a regra de repetir não tem onde morar a não ser na classe base, que passa então a saber da subclasse de que não deveria saber. Com composição o notificador guarda um transporte, e repetir é um transporte que embrulha outro.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"176\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">herança — ele É um tipo de</text> <rect x=\"20\" y=\"36\" width=\"312\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"176\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Notifier, e agora o sinal de repetir</text> <rect x=\"20\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"94\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">NotificadorSms</text> <rect x=\"184\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"258\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">NotificadorLog</text> <path d=\"M94 112 L94 82\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M258 112 L258 82\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"176\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a base sabe qual subclasse repete</text> <text x=\"544\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">composição — ele TEM um</text> <rect x=\"388\" y=\"36\" width=\"312\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"544\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Notifier</text> <path d=\"M544 82 L544 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"556\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">transporte</text> <rect x=\"388\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Repetindo(Sms())</text> <rect x=\"552\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"626\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Log()</text> <text x=\"544\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">repetir embrulha um transporte e nada mais muda</text> </svg>", "caption": "O requisito que chega nunca é outro tipo. É algo que acontece EM VOLTA de um, e só um destes dois desenhos tem onde pôr isso."}
```

Com composição isso é um `TransporteComRepeticao` que guarda outro transporte e o chama de novo.
Nada herda de nada, e o notificador de log não repete porque ninguém o envolveu.

## O que isso faz com um teste

Para testar a subclasse de e-mail você precisa testar a classe base junto, porque elas são um
objeto só. Para testar o notificador composto você entrega a ele um transporte que registra o que
recebeu — um objeto com um método — e o notificador não nota a diferença. **Essa é a diferença
prática, e ela aparece muito antes da diferença de projeto.**

## O custo

Composição é um objeto a mais e um nome a mais. `self.transport.deliver(...)` é uma palavra mais
longo que `self.deliver(...)`, e onde uma classe genuinamente É uma especialização de outra, essa
palavra não compra nada.

**Nenhuma das duas é o padrão para tudo.** O que é padrão é a PERGUNTA — é um tipo, ou tem um —
feita antes de qualquer uma das duas ser escrita.
