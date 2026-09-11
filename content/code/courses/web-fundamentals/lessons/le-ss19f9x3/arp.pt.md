---
title: Perguntar ao fio
version: 1
---

A sua máquina tem um pacote para `192.168.1.99`. A máscara diz que esse endereço é local, então não
há gateway envolvido: o quadro vai direto.

Só que um quadro é endereçado a um **MAC**, e a sua máquina não conhece o MAC de `192.168.1.99`.
Ela tem um endereço de uma camada e precisa de um da outra, e nada do que lhe disseram até aqui liga
os dois.

## A resposta é gritar

Não existe diretório. Nada numa rede local guarda uma lista de qual IP pertence a qual placa. Então
a máquina pergunta a todo mundo de uma vez.

Ela monta um quadro endereçado ao MAC de **broadcast** — `ff:ff:ff:ff:ff:ff`, que toda placa do fio
aceita — carregando uma pergunta: *quem tem `192.168.1.99`? Avise `192.168.1.24`.*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma máquina manda uma pergunta em broadcast para outras quatro no mesmo fio. Três a ignoram. A que tem o endereço responde diretamente com o MAC dela.\"><rect x=\"14\" y=\"40\" width=\"132\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perguntando</text><text x=\"80\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.24</text><text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">para ff:ff:ff:ff:ff:ff — quem tem 192.168.1.99?</text><rect x=\"246\" y=\"40\" width=\"108\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"300\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.7</text><text x=\"300\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não sou eu</text><rect x=\"366\" y=\"40\" width=\"108\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"420\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.8</text><text x=\"420\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não sou eu</text><rect x=\"486\" y=\"40\" width=\"120\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"546\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.168.1.99</text><text x=\"546\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sou eu</text><path d=\"M146 66 L242 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M358 66 L362 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M478 66 L482 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M486 122 L150 122\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"318\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">direto de volta, não para todos: a4:83:e7:2f:91:0c</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a pergunta vai para todos; a resposta vai para um</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e os dois anotam o par por alguns minutos</text></svg>", "caption": "Não há diretório, então a máquina pergunta ao fio inteiro. Só a que reconhece o endereço responde."}
```

Toda máquina do fio recebe a pergunta. Toda máquina que não é `192.168.1.99` a descarta. A que é
responde — **diretamente, não para todo mundo** — com o endereço MAC dela.

Essa troca é o **ARP**, o protocolo de resolução de endereços, e é a junção entre as duas camadas
de que esta aula trata.

## O cache, e por que o primeiro pacote é mais lento

Fazer isso antes de cada quadro seria absurdo, então a resposta é anotada. Toda máquina mantém um
**cache ARP** de pares IP-para-MAC, tipicamente por alguns minutos.

É por isso que o primeiríssimo pacote para uma máquina com quem você não falou recentemente é um
pouco mais lento: há um broadcast e uma resposta antes de ele poder sequer ser embrulhado. É um
milissegundo numa rede local, e é a razão de a primeira tentativa de qualquer coisa nunca ser a que
se mede.

As entradas expiram de propósito. Uma placa pode ser trocada, uma máquina pode receber outro
endereço, e um cache que nunca esquecesse estaria errado para sempre depois de qualquer das duas.

## O que uma máquina faz antes de perguntar

O cache é consultado primeiro, obviamente. O que é menos óbvio é que uma máquina o preenche sem ter
sido pedido.

Como a pergunta é um broadcast, **toda máquina do fio a vê** — e a pergunta carrega o endereço e o
MAC de quem perguntou. Então uma máquina que ouve *quem tem `.99`? avise `.24`* aprende onde está
`.24`, se importando com isso ou não. Quando duas máquinas precisam falar, cada uma muitas vezes já
ouviu falar da outra.

Algumas vão além e se anunciam de propósito. Uma máquina que acabou de receber um endereço manda uma
pergunta sobre o **próprio** endereço — não porque espere resposta, mas para que tudo no fio
atualize o cache, e para que uma resposta revelasse alguém já usando aquele endereço. É assim que um
endereço duplicado é detectado, e é por isso que duas máquinas configuradas com o mesmo endereço
produzem uma reclamação nas duas em vez de silêncio.

## Ninguém confere a resposta

Aqui está a parte que vale levar para além deste curso.

**O ARP não tem autenticação de espécie alguma.** A pergunta vai para todo mundo, e a primeira
resposta é acreditada. Nada verifica que a máquina respondendo é a que tem o endereço, porque não há
nada numa rede local que pudesse fazer a verificação.

Então qualquer máquina do seu fio pode responder *eu sou o gateway* e receber tráfego destinado ao
gateway. Isso se chama envenenamento de ARP, é a base da maioria dos ataques que acontecem numa rede
local em vez de pela internet, e não é um bug: é como um protocolo projetado em 1982 para um cabo
confiável se parece hoje.

A consequência prática é simples e é por que o HTTPS importa mais do que as pessoas acham. **Uma
rede local não é um lugar onde você possa confiar em com quem está falando.** O que protege você é a
criptografia entre as duas pontas, não o fio entre elas.

## O IPv6 faz diferente e igual

O IPv6 não tem ARP. Ele usa *descoberta de vizinhos*, que pergunta a um grupo em vez de gritar para
todo mundo, e é um desenho mais comportado.

Ele resolve o mesmo problema na mesma forma — uma pergunta no fio local, uma resposta, um cache com
prazo — e herda quase as mesmas propriedades de confiança. Conhecer a forma é o que se transfere.

## Onde isto te deixa

O ARP é como uma máquina transforma um endereço IP local no endereço MAC de que um quadro precisa:
uma pergunta em broadcast, uma resposta direta, e um cache de vida curta. É a junção entre o endereço
que atravessa o mundo e o endereço que atravessa um fio, e confia em quem responder primeiro.

Tudo isso supôs que a sua máquina já tem um endereço. **De onde ele veio?** Ninguém digitou. Essa é
a próxima seção, e é a última peça antes do vídeo.
