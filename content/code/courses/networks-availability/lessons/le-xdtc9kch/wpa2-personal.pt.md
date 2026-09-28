---
title: WPA2-Personal, uma passphrase para todo mundo
version: 1
---

Numa **rede aberta nada é criptografado**. Todo quadro, depois do cabeçalho de rádio, pode ser lido por
qualquer receptor ao alcance. É por isso que o Wi-Fi de uma cafeteria só é tão privado quanto o que roda
por cima dele, HTTPS por exemplo (aula 5 de `networks`). O WPA2-Personal acrescenta criptografia com um
segredo compartilhado, a **passphrase**: de 8 a 63 caracteres, digitada em todos os aparelhos.

## Da passphrase à chave

A passphrase não é a chave. O AP e o cliente a transformam numa **PMK** de 256 bits, a pairwise master
key, com a mesma função, e toda a derivação cabe numa linha de Python:

```schooling-example
{"language": "python", "file": "psk.py", "parts": [{"code": "import hashlib\nimport math", "note": "Nada a instalar: o PBKDF2 está na biblioteca padrão do Python, porque é um jeito comum de transformar uma senha em chave."}, {"code": "def pmk(passphrase, ssid):\n    return hashlib.pbkdf2_hmac(\"sha1\", passphrase.encode(), ssid.encode(), 4096, 32)", "note": "Toda a derivação de chave do WPA2-Personal. A passphrase passa 4.096 vezes pelo HMAC-SHA1, com o nome da rede como sal, e saem 32 bytes: a PMK, 256 bits."}, {"code": "print(\"password @ IEEE     \", pmk(\"password\", \"IEEE\").hex())\nprint(\"password @ IEEE-2   \", pmk(\"password\", \"IEEE-2\").hex())\nprint()", "note": "A primeira linha é o vetor de teste que a norma 802.11 publica, passphrase `password` na rede `IEEE`, e a chave impressa abaixo é a que a norma dá. A segunda muda só o nome da rede."}, {"code": "choices = [\n    (\"8 lowercase letters\", 26, 8),\n    (\"10 letters and digits\", 62, 10),\n    (\"5 words from 7776\", 7776, 5),\n    (\"20 printable characters\", 94, 20),\n]", "note": "Quatro jeitos de escolher uma passphrase. Cada um é um alfabeto e um comprimento, e o tamanho do espaço que alguém teria de vasculhar é o alfabeto elevado ao comprimento."}, {"code": "for name, alphabet, length in choices:\n    bits = length * math.log2(alphabet)\n    print(f\"{name:24} {bits:6.1f} bits  {float(alphabet) ** length:9.1e} candidates\")", "note": "Bits são a mesma conta em escala logarítmica: cada bit a mais dobra o espaço. Qual mirar é o argumento da seção abaixo."}], "output": "password @ IEEE      f42c6fc52df0ebef9ebb4b90b38a5f902e83fe1b135a70e23aed762e9710a12e\npassword @ IEEE-2    9906cb57a6ddbdc32db106d33afe45b8b2713ea52d1abb8a4b8ed6025c7b8c4b\n\n8 lowercase letters        37.6 bits    2.1e+11 candidates\n10 letters and digits      59.5 bits    8.4e+17 candidates\n5 words from 7776          64.6 bits    2.8e+19 candidates\n20 printable characters   131.1 bits    2.9e+39 candidates"}
```

A primeira linha da saída bate com o vetor de teste da norma 802.11, então a função acima é a verdadeira.
A segunda linha mostra por que o nome da rede entra na conta: **a mesma passphrase numa rede com outro
SSID dá uma chave sem relação nenhuma.** O nome é o sal, e isso torna inútil contra uma rede o trabalho
feito contra outra. Uma rede que ainda usa o nome de fábrica do roteador divide o sal com todas as outras
que o mantiveram.

## O four-way handshake

Conhecer a PMK é o que o cliente precisa provar, e ele prova sem enviá-la. Quando um cliente se associa, o
AP e o cliente trocam quatro mensagens EAPOL-Key:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 378\" role=\"img\" aria-label=\"Uma sequência entre um cliente à esquerda e um ponto de acesso à direita, os dois já com a PMK. Mensagem 1, do AP: ANonce, um número aleatório. Mensagem 2, do cliente: SNonce e um MIC; o cliente já calcula a PTK. Mensagem 3, do AP: a chave de grupo, GTK, cifrada, e um MIC, que prova que o AP tem a PMK. Mensagem 4, do cliente: uma confirmação e um MIC. Aí as chaves são instaladas e o tráfego é cifrado com a PTK. A PMK em si nunca atravessa o ar.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"80\" y=\"16\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><text x=\"150.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">a estação</text><rect x=\"480\" y=\"16\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ponto de acesso</text><text x=\"550.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AP</text><path d=\"M150 56 L150 330\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M550 56 L550 330\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"250\" y=\"66\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os dois já têm a PMK</text><text x=\"350\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1  ANonce, um número aleatório</text><path d=\"M550 124 L156 124\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"350\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2  SNonce, e um MIC</text><path d=\"M150 174 L544 174\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"350\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o cliente já calcula a PTK</text><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3  a chave de grupo (GTK), cifrada, e um MIC</text><path d=\"M550 224 L156 224\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"350\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o MIC prova que o AP tem a PMK</text><text x=\"350\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4  confirmação, e um MIC</text><path d=\"M150 274 L544 274\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><rect x=\"200\" y=\"318\" width=\"300\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">chaves instaladas: tráfego cifrado com a PTK</text><text x=\"350\" y=\"362\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a PMK em si nunca atravessa o ar</text></svg>", "caption": "O four-way handshake do WPA2, que o WPA3 mantém. Cada lado prova que tem a PMK calculando um MIC com chaves derivadas dela; a chave nunca é enviada. Desenhado a partir da norma: o laboratório não tem rádio para capturar um."}
```

Cada lado contribui com um número aleatório, o ANonce e o SNonce. A partir da PMK, dos dois nonces e dos
dois endereços MAC, os dois calculam a mesma **PTK**, a pairwise transient key, nova para esta associação.
Uma parte da PTK assina cada mensagem da 2 em diante com um MIC, um código de integridade de mensagem,
então um lado que errou a PMK produz um MIC que o outro rejeita. A mensagem 3 também entrega a **GTK**, a
chave de grupo para quadros de broadcast, cifrada. Depois da mensagem 4, os dados vão cifrados com AES no
modo CCMP.

## Por que o tamanho da passphrase importa

As mensagens 1 e 2 atravessam o ar em claro: os dois nonces, os dois endereços e um MIC calculado a partir
da PMK. Então **um handshake gravado permite a qualquer um testar palpites da passphrase offline**, tão
rápido quanto o hardware dele roda o PBKDF2, sem nenhum contato a mais com a rede e sem nada em log
nenhum. A defesa não é uma configuração. É uma passphrase com um espaço de busca grande demais para ser
percorrido, e a tabela do exemplo põe números nisso.

**Oito letras minúsculas são 37,6 bits, 2,1e+11 candidatas**, e isso se fossem aleatórias. Cinco palavras
sorteadas de uma lista de 7.776 são 64,6 bits, umas 136 milhões de vezes mais. Vinte caracteres
imprimíveis aleatórios são 131,1 bits. A escolha de uma pessoa, uma palavra com um ano depois, é bem menor
do que o alfabeto sugere, porque os palpites são testados em ordem de probabilidade. **Use uma passphrase
aleatória de 20 caracteres ou mais, ou cinco palavras ou mais sorteadas**, e guarde-a num gerenciador de
senhas.

Duas fraquezas sobrevivem a qualquer tamanho, porque vêm de a chave ser compartilhada:

- Quem conhece a passphrase consegue ler o tráfego de outros clientes se gravou os handshakes deles, já
  que todo o resto que entra na PTK é enviado em claro. O WPA2-Personal barra estranhos, não colegas.
- Não há sigilo futuro (forward secrecy). Uma passphrase que vaza no ano que vem decifra uma gravação
  feita neste ano.

E quando uma pessoa sai, o único jeito de revogá-la é trocar a passphrase em todos os aparelhos. O WPA3
responde às duas primeiras; o 802.1X, na seção sobre o modo enterprise, responde à terceira.
