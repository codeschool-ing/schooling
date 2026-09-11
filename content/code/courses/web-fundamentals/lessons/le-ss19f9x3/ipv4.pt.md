---
title: Ler um endereço
version: 1
---

Um endereço IPv4 são quatro números separados por pontos: `198.51.100.4`. Todos eles ficam entre 0
e 255, e o motivo vale trinta segundos porque explica tudo o mais nesta aula.

## Quatro bytes, escritos para pessoas

O endereço é na verdade um número só, de trinta e dois bits. Ninguém consegue ler trinta e dois
bits, então ele é escrito como quatro grupos de oito — quatro bytes — e oito bits contam de 0 a
255.

É essa a notação inteira. `256.0.0.1` não é um endereço válido escrito de um jeito estranho; não é
um endereço, do mesmo jeito que um dia 32 não é uma data.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 176\" role=\"img\" aria-label=\"Um endereço mostrado duas vezes. Acima, trinta e dois bits em quatro grupos de oito. Abaixo, o mesmo valor escrito como quatro números decimais separados por pontos, cada um alinhado sob o seu grupo de bits.\"><text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um número só, de trinta e dois bits</text><rect x=\"24\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"102\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000110</text><rect x=\"196\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"274\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00110011</text><rect x=\"368\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"446\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">01100100</text><rect x=\"540\" y=\"44\" width=\"156\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"618\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00000100</text><text x=\"102\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">198</text><text x=\"274\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">51</text><text x=\"446\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">100</text><text x=\"618\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">4</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">oito bits contam de 0 a 255, e é daí que vem o teto de cada número</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os pontos são para você — nada na rede os enxerga</text></svg>", "caption": "Os pontos são pontuação acrescentada para pessoas. Para qualquer máquina isto é um único número de trinta e dois bits."}
```

Trinta e dois bits dão cerca de **quatro bilhões e um quarto** de endereços possíveis. Isso parecia
ilimitado quando o número foi escolhido, e é a razão de duas das seções seguintes desta aula
existirem.

## O seu provavelmente não é seu

Abra as configurações de rede e você muito provavelmente verá um endereço começando com
`192.168.`, ou `10.`, ou algo na faixa `172.16`–`172.31`.

Essas três faixas são **privadas**. Foram separadas de propósito, não são únicas no mundo, e nada
na internet roteia para elas. Milhões de casas usam `192.168.1.10` neste momento, e não há
conflito, porque nenhum pacote com esse destino jamais sai de uma rede local.

| faixa | tamanho | onde você encontra |
|---|---|---|
| `10.0.0.0` – `10.255.255.255` | 16,7 milhões | empresas, redes de nuvem, sites maiores |
| `172.16.0.0` – `172.31.255.255` | 1 milhão | contêineres e máquinas virtuais, com frequência |
| `192.168.0.0` – `192.168.255.255` | 65 mil | quase todo roteador doméstico já vendido |

Então uma máquina em casa tem um endereço **privado** que a identifica na sua rede, e compartilha
um único endereço **público** com tudo o mais do prédio. O vídeo no fim desta aula é sobre o
maquinário que junta os dois.

## Por que a notação sobrevive sendo esquisita

Quatro números com pontos é um jeito estranho de escrever um valor de trinta e dois bits, e ele
sobreviveu a várias tentativas de substituição. Vale um instante porque a razão explica a próxima
seção.

A divisão em quatro bytes se alinha, grosso modo, com o modo como os endereços são **distribuídos**.
Blocos grandes são alocados em fronteiras de byte — um primeiro número inteiro, ou os dois
primeiros — então quem lê `198.51.x.x` percebe de relance que os dois primeiros números são a
alocação de alguém e os dois últimos são dessa pessoa para arranjar. Isso era mais verdade nos anos
1980 do que é hoje, e o hábito de ler um endereço da esquerda para a direita, do mais geral para o
mais específico, continua exatamente certo.

É a mesma forma de um número de telefone ou de um CEP: a esquerda é onde, a direita é qual. O que
mudou foi que a fronteira deixou de cair num ponto, e é para isso que serve a máscara da próxima
seção.

## Três endereços que não são máquinas

Alguns valores significam outra coisa que não "um computador em particular", e aparecem o
bastante para valer reconhecê-los.

`127.0.0.1` é o **loopback** — esta máquina, falando com ela mesma. Ele nunca chega a uma placa de
rede; o sistema operacional o devolve direto. É para ele que `localhost` resolve, e é por isso que
um servidor de desenvolvimento no seu notebook é alcançável do seu notebook e de mais lugar nenhum.

O **primeiro endereço de uma faixa** nomeia a própria rede em vez de qualquer coisa dentro dela. O
**último** é o endereço de broadcast: tudo nesta rede de uma vez. Nenhum dos dois pode ser dado a
uma máquina, que é por que uma faixa de 256 endereços tem 254 utilizáveis, e essa conta é a próxima
seção.

E `0.0.0.0` significa, dependendo de onde você o encontra, *ainda sem endereço* ou *todos os
endereços desta máquina*. Um servidor "escutando em `0.0.0.0`" está escutando em todos eles.

## Os endereços acabaram

Quatro bilhões de endereços e cerca de oito bilhões de pessoas, a maioria carregando vários
aparelhos conectados. A conta parou de fechar nos anos 1990, e os últimos blocos grandes foram
distribuídos por volta de 2011.

Três coisas aconteceram em resposta, e cada uma é uma seção desta aula ou da próxima:

- **endereços privados e NAT**, para que uma casa precise de um endereço público em vez de vinte;
- **IPv6**, que é um número maior e a resposta de verdade;
- **um mercado**, onde blocos de endereços IPv4 hoje são comprados e vendidos por dinheiro real.

A terceira não é uma tecnologia e vale saber mesmo assim, porque explica por que um provedor de
nuvem cobra por um endereço público que costumava ser de graça.

## Onde isto te deixa

Um endereço IPv4 são trinta e dois bits escritos como quatro números de 0 a 255. O que a sua
máquina te mostra provavelmente é privado — único na sua rede e sem sentido fora dela — e não é o
endereço pelo qual o resto do mundo te enxerga. Alguns valores são reservados para a própria
máquina, para a própria rede, e para tudo de uma vez.

O que nada disso te diz ainda é **quais endereços contam como locais**. Isso é um segundo número,
ele fica ao lado do endereço em toda configuração de rede que você já viu, e é a próxima seção.
