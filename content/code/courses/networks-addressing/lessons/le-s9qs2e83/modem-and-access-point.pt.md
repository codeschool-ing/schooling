---
title: "Modem e ponto de acesso: onde o cabo acaba"
version: 1
---

Os outros equipamentos desta aula movem quadros entre cabos do mesmo tipo. Estes dois ficam na
borda, onde a Ethernet encontra um meio que não é Ethernet: a linha do provedor de um lado do
prédio, o rádio do outro. **Nenhum dos dois foi executado neste laboratório**, que não tem linha
telefônica, nem cabo coaxial, nem rádio; esta seção os descreve e não mostra saída.

## O modem

A palavra vem de *modulador-demodulador*. **Um modem transforma o sinal que a linha do provedor
carrega em quadros que um computador usa, e de volta.** A linha é o que chegou ao prédio: um par
telefônico no DSL, um cabo coaxial de uma rede de TV a cabo, ou uma fibra. Cada um tem o seu jeito
de pôr bits no meio e as suas regras para dividi-lo com os vizinhos, e o modem é o equipamento que
fala essa língua; do outro lado ele oferece uma porta Ethernet comum. Na fibra, o mesmo trabalho é
feito por um terminal óptico, que os provedores chamam de ONT e os clientes continuam chamando de
modem.

Então um modem vive na camada 1, mais a camada de enlace que a tecnologia do provedor usa na
linha. Ele não lê endereço IP. Quando a linha cai, as luzes do próprio modem mostram isso antes de
qualquer computador, e é por isso que a primeira pergunta num atendimento sobre conexão de casa é o
que essas luzes mostram.

## O ponto de acesso

**Um ponto de acesso é uma ponte entre o rádio e o cabo.** Celulares e laptops mandam para ele
quadros Wi-Fi, que levam endereços MAC como os da Ethernet, e ele os repassa para a rede cabeada, e
devolve pelo ar os quadros da rede cabeada. Ele trabalha nas camadas 1 e 2: o rádio, e os quadros
nele. Um ponto de acesso não roteia e não distribui endereços; o roteador e o servidor DHCP atrás
dele fazem isso, e a aula 10 trata do segundo.

Dois fatos sobre o rádio mudam o jeito de usar pontos de acesso:

- **Todas as estações de um canal dividem o mesmo ar**, como as máquinas de um hub dividem um cabo.
  Só uma delas transmite de cada vez, então um único ponto de acesso com quarenta celulares fica
  lento para os quarenta.
- **Cobertura é questão de distância e de paredes.** Um prédio é coberto por vários pontos de
  acesso na mesma rede cabeada, cada um no seu canal e todos anunciando o mesmo nome de rede, e um
  celular passa de um para o outro enquanto o dono caminha.

## A caixa na estante

O equipamento que um provedor instala numa casa é tudo isso num gabinete só:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A caixa que um provedor instala em uma casa, aberta. Dentro de um só gabinete há quatro equipamentos. A linha do provedor entra em um modem, que transforma o sinal da linha em Ethernet. O modem alimenta um roteador fazendo NAT, que dá à casa um endereço público. O roteador alimenta um switch com algumas portas Ethernet para PCs cabeados e um ponto de acesso que transforma rádio em Ethernet para aparelhos Wi-Fi.\"><defs><marker id=\"l1-home-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"30\" width=\"452\" height=\"205\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"162\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um gabinete, quatro equipamentos</text><rect x=\"162\" y=\"108\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">modem</text><text x=\"172\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linha para Ethernet</text><rect x=\"300\" y=\"108\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">roteador + NAT</text><text x=\"310\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um endereço público</text><rect x=\"438\" y=\"60\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">switch</text><text x=\"448\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">algumas portas Ethernet</text><rect x=\"438\" y=\"162\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">ponto de acesso</text><text x=\"448\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rádio para Ethernet</text><path d=\"M282 133 L300 133\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420 125 L438 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420 141 L438 182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"14\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linha do provedor</text><text x=\"14\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fibra, cabo, DSL</text><path d=\"M118 133 L162 133\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M588 85 L612 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"616\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PCs no cabo</text><path d=\"M588 187 L612 187\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"616\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aparelhos Wi-Fi</text></svg>", "caption": "O que é o \"roteador\" de casa: quatro equipamentos em um gabinete. Uma rede de empresa os mantém separados.", "same": ["modem", "switch"]}
```

Um modem na direção da linha do provedor, um roteador que faz NAT para a casa inteira dividir um
endereço público, um switch pequeno com algumas portas atrás, e um ponto de acesso. **O que todo
mundo chama de "o roteador" em casa são quatro equipamentos**, e é por isso que ele é a coisa que
todo mundo reinicia: quatro trabalhos, uma tomada.

Uma rede de empresa desmonta a caixa de propósito. O equipamento do provedor termina no modem ou
terminal dele; o roteador e o firewall da empresa vêm depois; os switches ficam num rack; e os
pontos de acesso se espalham pelos tetos, cada um alimentado por um único cabo que também leva a
energia, o que é a aula 21. Equipamentos separados podem ser trocados, dimensionados e colocados
onde funcionam melhor, um de cada vez, e quando um falha os outros três continuam funcionando.
