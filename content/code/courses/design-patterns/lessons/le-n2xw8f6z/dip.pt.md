---
title: "Inversão de dependência: os detalhes dependem da regra"
version: 1
---

**O princípio da inversão de dependência diz que o código que guarda as regras de um programa não
deve depender do código que conversa com o mundo de fora; os dois devem depender de uma abstração,
e a abstração pertence às regras.** Nas palavras de Martin, módulos de alto nível não devem
depender de módulos de baixo nível, e abstrações não devem depender de detalhes. A *inversão* é da
seta no código-fonte: ela acaba apontando do detalhe para a regra.

Duas leituras erradas são comuns. A primeira é que o princípio é a mesma coisa que injeção de
dependência, passar um objeto em vez de construí-lo. Injeção é uma técnica, e a lição 5 trata dela;
dá para injetar uma classe de e-mail concreta e não inverter nada. A segunda é que acrescentar uma
interface basta. Uma interface que mora ao lado do código de e-mail e espelha os métodos dele ainda
deixa as regras dependendo do pacote de e-mail. **O que decide é quem é dono da abstração, e para
que lado apontam as linhas de `import`.**

## Regra e detalhe

Na biblioteca, a *regra* é a dos empréstimos atrasados: catorze dias, 50 centavos por dia, um aviso
a quem estiver atrasado. Os *detalhes* são como o aviso viaja: um servidor de e-mail, um gateway de
SMS, uma impressora no balcão. A regra é o que a biblioteca é; os detalhes mudam sempre que muda um
fornecedor ou um contrato.

Escrita do jeito óbvio, a regra chama o detalhe:

```python
from smtp_mailer import SmtpMailer      # the rules import the mail code


class OverdueNotices:
    def __init__(self):
        self.mailer = SmtpMailer("smtp.example.org")

    def send(self, loans, today):
        ...
        self.mailer.send_mail(address, subject, body)
```

A seta vai das regras para o código de e-mail. Para rodar as regras você precisa do código de
e-mail; para testá-las, de um servidor de e-mail ou de uma biblioteca de mock que finja ser um; para
trocar e-mail por SMS, você abre as regras e as edita. O código mais importante do programa depende
do código com mais chance de mudar.

## Virando a seta

A inversão move uma declaração. As regras dizem do que precisam, com as próprias palavras e no
próprio módulo: algo que consiga avisar um membro. O código de e-mail, onde quer que more, fornece
isso.

| | antes | depois |
|---|---|---|
| quem declara o que é preciso | ninguém: as regras usam o que a classe de e-mail oferecer | as regras, como um protocolo `Notifier` no próprio módulo |
| que módulo importa qual | as regras importam o código de e-mail | o código de e-mail importa o protocolo das regras, ou não importa nada e se encaixa no formato |
| para testar as regras | um servidor de e-mail, ou um mock dele | qualquer objeto com um método `notify` |
| para trocar para SMS | editar as regras | escrever uma classe de SMS e mudar as ligações |

As palavras importam. O protocolo se chama `Notifier` e o método `notify(member, text)`, porque é
isso que as regras querem fazer. Ele não se chama `Mailer` com `send_mail(address, subject, body)`,
que é o que um detalhe por acaso oferece. Uma abstração com o nome do detalhe é o detalhe com um `I`
na frente, e trocar para SMS continuaria exigindo mudá-la.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-inversion\" aria-label=\"Dois diagramas dos avisos de multa. À esquerda, antes: OverdueNotices importa SmtpMailer, então a seta desce das regras para o código de e-mail, e a regra depende do detalhe. À direita, depois: o módulo notices.py guarda OverdueNotices e o protocolo Notifier que ele usa, desenhado com um losango. Abaixo, em adapters.py, EmailNotifier e SmsNotifier apontam para cima, para Notifier, com ponta de seta vazada. As setas agora vão dos detalhes para a regra.\"><defs><marker id=\"l04-inversion-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">antes: as regras importam o detalhe</text><rect x=\"90.0\" y=\"60.0\" width=\"170.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"71.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M90.0 82.5 L260.0 82.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"98.0\" y=\"93.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send()</text><rect x=\"90.0\" y=\"200.0\" width=\"170.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"211.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SmtpMailer</text><path d=\"M90.0 222.5 L260.0 222.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"98.0\" y=\"233.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send_mail()</text><path d=\"M175.0 105.0 L175.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-inversion-dp-ah-amber)\"></path><text x=\"185.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">import</text><text x=\"175.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a regra depende do detalhe</text><path d=\"M355.0 20.0 L355.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"540.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">depois: o detalhe importa a porta das regras</text><rect x=\"380.0\" y=\"36.0\" width=\"320.0\" height=\"116.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"390.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notices.py</text><rect x=\"392.0\" y=\"70.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M392.0 92.5 L532.0 92.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"400.0\" y=\"103.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send()</text><rect x=\"560.0\" y=\"62.0\" width=\"130.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"625.0\" y=\"87.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Notifier</text><path d=\"M560.0 99.0 L690.0 99.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"110.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notify()</text><path d=\"M532.0 92.0 L560.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M532.0 92.0 L541.0 97.5 L550.0 92.0 L541.0 86.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M380.0 196.0 L700.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"390.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">adapters.py</text><rect x=\"392.0\" y=\"226.0\" width=\"140.0\" height=\"22.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462.0\" y=\"237.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">EmailNotifier</text><rect x=\"560.0\" y=\"226.0\" width=\"130.0\" height=\"22.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"237.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SmsNotifier</text><path d=\"M462.0 226.0 L462.0 176.0 L625.0 176.0 L625.0 121.5\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M625.0 121.5 L632.0 133.5 L618.0 133.5 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><path d=\"M625.0 226.0 L625.0 121.5\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M625.0 121.5 L632.0 133.5 L618.0 133.5 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"540.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o detalhe depende da regra</text></svg>", "caption": "As mesmas regras antes e depois da inversão. O protocolo foi para o módulo das regras, e as setas de import viraram."}
```

## Por que as regras merecem ser a ponta estável

Código do qual muitos dependem é caro de mudar, e código que não depende de nada é barato de testar.
O princípio arruma um programa para que o código com essas duas propriedades seja o código que
deveria tê-las: as regras, que só mudam quando a biblioteca muda de ideia. Servidores de e-mail,
gateways, bancos de dados e frameworks são trocados a cada poucos anos. A próxima seção constrói a
versão invertida e mostra as linhas de `import` que provam a direção.
