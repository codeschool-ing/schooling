---
title: Grupos de consumidores, uma posição por leitor
version: 1
---

**Um grupo de consumidores (consumer group) é a visão que uma aplicação tem do event hub inteiro**:
a sua própria posição em cada partição, separada da de todas as outras aplicações. A Quitanda tem dois
leitores de `clicks` que não querem nada um com o outro. A checagem de fraude lê cada clique em
segundos e procura um padrão de checkouts; a cópia para o lake também lê cada clique, no seu próprio
ritmo, e fica horas atrasada numa noite movimentada sem que ninguém se importe. Se dividissem uma
posição, o que um lesse o outro pularia. Com um grupo cada, os dois veem todos os eventos, e nenhum
sabe que o outro existe.

A configuração do emulador declarou um grupo além do `$Default`, que todo hub tem, e ele se chama
`fraud`. O `read_clicks.py` da seção anterior recebe o grupo como primeiro argumento:

```
ana@laptop:~/azure$ python read_clicks.py fraud
partition 0  seq  0  offset    0  c-05  #4  /bakery
partition 0  seq  1  offset  144  c-05  #8  /cart
partition 1  seq  0  offset    0  c-02  #2  /search?q=banana
partition 1  seq  1  offset  152  c-02  #5  /cart
partition 3  seq  0  offset    0  c-17  #1  /fruit
partition 3  seq  1  offset  144  c-17  #3  /fruit/banana
partition 3  seq  2  offset  296  c-17  #6  /cart
partition 3  seq  3  offset  440  c-03  #7  /dairy
partition 3  seq  4  offset  584  c-17  #9  /checkout
partition 3  seq  5  offset  728  c-03  #10 /cart
```

**Os mesmos dez cliques, nas mesmas partições, nos mesmos números de sequência**, pela segunda vez.
O `$Default` leu todos eles um minuto atrás e nada no hub mudou. Essa é a ideia inteira, e é o
contrário de uma fila, onde o segundo leitor teria encontrado uma fila vazia.

## Um grupo que não existe

O emulador conhece dois grupos, `$Default` e `fraud`. Peça um terceiro a ele:

```
ana@laptop:~/azure$ python read_clicks.py analytics
```

**Nada: nem cliques, nem erro**, mesmo com o `on_error` no programa. O leitor escutou por cinco
segundos e não ouviu nada, o que parece exatamente um hub sem tráfego. No Azure o serviço recusa um
grupo de consumidores que não existe, e a documentação da Microsoft descreve um erro de "não
encontrado" que nomeia a entidade; este emulador, nesta execução, respondeu com silêncio. **Um leitor
que não ouve nada não provou nada**, e o hábito a levar daqui é conferir, antes de confiar num leitor
calado, se o hub tem eventos: o `partitions.py` teria dito dez.

No Azure um grupo é criado como qualquer outra parte do hub, pelo portal, pela linha de comando ou por
uma declaração como o Terraform da seção sobre o Capture desta lição, e não pelo primeiro leitor que
o nomeia. A camada limita quantos um hub pode ter: a documentação da Microsoft dá um no Basic, que é o
`$Default` sozinho, e vinte no Standard, com mais no Premium e no Dedicated. Um grupo por aplicação
que lê o stream é a regra prática, e vinte acabam antes do que parece quando cada equipe quer o seu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma partição, a partição 3 de clicks, desenhada como uma fileira de eventos numerados de 0 a 11. Eventos novos entram à direita; eventos mais velhos que a retenção são descartados à esquerda. Dois consumer groups apontam para lugares diferentes da mesma fileira: $Default tem um checkpoint no número de sequência 11, e fraud leu até o número de sequência 5. Nenhuma das posições move a outra.\" data-fig=\"l22-groups\"><text x=\"360\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 3 de clicks</text><rect x=\"20\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"80\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">eventos antigos: descartados</text><text x=\"80\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ao fim da retenção</text><rect x=\"150\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"167\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"190\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"207\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"230\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"247\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"270\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"287\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"310\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"327\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"350\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"367\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"390\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"407\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"430\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"447\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"470\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"510\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"527\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"550\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"590\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11</text><line x1=\"632\" y1=\"60\" x2=\"656.0\" y2=\"60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"662,60 656.0,63.0 656.0,57.0\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"668\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">eventos novos</text><line x1=\"607\" y1=\"140\" x2=\"607.0\" y2=\"86.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"607,80 610.0,86.0 604.0,86.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"597\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">$Default: checkpoint em 11</text><line x1=\"367\" y1=\"110\" x2=\"367.0\" y2=\"86.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"367,80 370.0,86.0 364.0,86.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"367\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fraud: leu até o 5</text></svg>", "caption": "Um log, duas posições: cada consumer group guarda o próprio lugar em cada partição, e ler não muda nada no log."}
```

## Quantos leitores num grupo

**Dentro de um grupo, cada partição deve ter um leitor por vez.** Vários programas da mesma
aplicação, dividindo um grupo, repartem as partições entre si: com quatro partições e duas cópias da
checagem de fraude, cada cópia lê duas. O serviço permite até cinco leitores numa partição num grupo,
e a documentação da Microsoft recomenda um, porque cada um dos cinco recebe todos os eventos daquela
partição: cinco leitores são cinco cópias do trabalho, não um quinto para cada.

**É por isso que o número de partições é o teto da leitura em paralelo.** Um hub com quatro partições
mantém ocupados no máximo quatro leitores de um grupo; uma quinta cópia da checagem de fraude não
ganha partição própria e só espera que alguma das outras morra. A escolha da Quitanda de quatro
partições para `clicks` é, então, também a escolha de que a checagem de fraude nunca vai rodar em
mais de quatro máquinas ao mesmo tempo.

Repartir as partições entre as cópias é um trabalho à parte, chamado balanceamento de carga, e
ninguém deveria escrevê-lo à mão. A biblioteca faz isso pelo mesmo lugar onde guarda os checkpoints,
que é a próxima seção: cada cópia registra quais partições são dela, e assume uma partição cujo dono
parou de renovar o pedido.
