---
title: Um proxy, não um SDK
version: 2
---

Toda ferramenta até aqui foi alimentada de dentro da aplicação: spans escritos pelo assistente, ou por
uma biblioteca carregada nele. O **Helicone** começa pelo outro lado. Ele é um gateway: a aplicação manda
os seus pedidos a modelo para o Helicone em vez do fornecedor, o Helicone os repassa, e registra cada
pedido e resposta enquanto passam. A integração é uma troca de URL base e um cabeçalho com a chave do
Helicone, e nada mais no programa muda.

Esse é todo o seu atrativo, e todo o seu limite:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As quatro etapas do assistente, embed, search, generate e check citations, dentro da aplicação. Spans escritos na aplicação veem as quatro. Um gateway fica do lado de fora, entre a aplicação e o fornecedor, e vê só as duas chamadas que passam por ele: o pedido de embedding e o pedido ao modelo.\"><rect x=\"10\" y=\"10\" width=\"430\" height=\"230\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dentro da aplicação: o que os spans veem</text><rect x=\"40\" y=\"50\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">embed</text><rect x=\"40\" y=\"100\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search</text><rect x=\"40\" y=\"150\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">generate</text><rect x=\"40\" y=\"200\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_citations</text><rect x=\"300\" y=\"95\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index.json</text><path d=\"M210 115 L300 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"470\" y=\"40\" width=\"90\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"515\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">gateway</text><rect x=\"610\" y=\"40\" width=\"100\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fornecedor</text><path d=\"M210 65 L470 65\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M210 165 L470 165\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M560 65 L610 65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M560 165 L610 165\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"515\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um gateway só vê estas</text></svg>", "caption": "Um gateway está no fio até o fornecedor. Ele vê toda chamada a modelo, de qualquer programa, e nada do que acontece entre elas.", "same": ["gateway"]}
```

**O que um gateway ganha de graça.** Toda chamada a modelo de todo programa que use a chave, em qualquer
linguagem, inclusive as que ninguém lembrou de instrumentar. A pior lacuna da aula 3, chamadas que
ninguém rastreou, se fecha, porque não há como chegar ao fornecedor a não ser por ele. Os tokens, o
custo, a latência e o status vêm direto da resposta do próprio fornecedor, então estão certos por
construção.

**O que ele não vê.** Nada que não seja uma chamada a modelo: a busca, o piso, os trechos mantidos, a
conferência das citações. A aula 5 achou a causa das recusas de pedidos na melhor nota do span de
busca; um gateway teria mostrado uma queda de chamadas a modelo e nada sobre o porquê. Ele também não
vê quais chamadas andam juntas, a menos que a aplicação diga isso com um cabeçalho em cada pedido.

Então um gateway recebe **cabeçalhos** onde um SDK recebe atributos: o usuário, a sessão e a
funcionalidade viajam com cada pedido, porque o gateway não tem outro jeito de saber deles. A próxima
seção mostra o que um gateway vê sem eles.

## O que um gateway faz e um rastreador não

Por estar no caminho de todo pedido, um gateway pode **agir** sobre eles além de registrá-los: responder
a um pedido repetido a partir de um cache sem chamar o fornecedor, recusar um usuário acima de um limite
de taxa, tentar outro fornecedor quando o primeiro falha, e guardar as chaves dos fornecedores para que
as aplicações nunca as tenham. São os orçamentos da aula 3 e as novas tentativas da aula 4, saindo da
aplicação para a infraestrutura. É um ganho real para uma empresa com muitas aplicações e uma conta só,
e um custo real: mais um serviço no caminho crítico de toda resposta, somando a sua própria latência e
as suas próprias quedas, e guardando todo prompt e toda resposta nos seus logs.
