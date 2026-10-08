---
title: Assar uma imagem, ou configurar no boot
version: 2
---

Toda máquina parte de uma imagem: um disco com um sistema operacional, copiado para cada máquina
nova. A pergunta desta aula é **quando o software da loja chega a esse disco**, e há duas
respostas.

**Configurar no boot** liga toda máquina a partir de uma imagem limpa e instala o que ela precisa
enquanto ela sobe: um script entregue à máquina no lançamento (na AWS, o *user data*, que o
cloud-init executa), ou o Ansible entrando um minuto depois, como na aula 18. Em inglês isso tem
apelido, *frying*, fritar: o trabalho é feito na hora, toda vez, na máquina que precisa dele.

**Assar** (*baking*) faz esse trabalho uma vez, antes de qualquer máquina existir. Um build instala
o nginx, escreve a configuração e a página, e salva o resultado como uma imagem nova. Toda máquina
então liga a partir dessa imagem e não tem mais nada a instalar.

A crença comum é que os dois dão o mesmo resultado, e que assar é uma otimização do tempo de boot.
Não dão o mesmo resultado. Uma máquina que instala o nginx no boot recebe a versão que o repositório
oferece **no dia em que ela liga**. Três máquinas ligadas em três dias diferentes rodam o que três
dias diferentes ofereciam, e nada em arquivo nenhum diz qual:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois jeitos de pôr o nginx em três máquinas ligadas no dia 1, no dia 9 e no dia 20. Configurada no boot, cada máquina parte de uma imagem limpa e instala o nginx do repositório no dia em que liga, então cada uma pode receber uma versão diferente. Assada, o Packer constrói uma imagem no dia 0 e toda máquina liga como cópia dela, então as três rodam a mesma coisa.\"><defs><marker id=\"bf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 0</text><text x=\"280.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 1</text><text x=\"450.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 9</text><text x=\"620.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 20</text><text x=\"20.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">configurar no boot</text><rect x=\"220\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boot</text><text x=\"280.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imagem limpa</text><text x=\"280.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ o apt do dia 1</text><rect x=\"390\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boot</text><text x=\"450.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imagem limpa</text><text x=\"450.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ o apt do dia 9</text><rect x=\"560\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boot</text><text x=\"620.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imagem limpa</text><text x=\"620.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ o apt do dia 20</text><text x=\"450.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">três máquinas, talvez três versões</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">assar uma imagem, ligar cópias</text><rect x=\"40\" y=\"165\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">packer build</text><text x=\"110.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><rect x=\"220\" y=\"165\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ligar</text><text x=\"280.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><rect x=\"390\" y=\"165\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ligar</text><text x=\"450.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><rect x=\"560\" y=\"165\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ligar</text><text x=\"620.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><path d=\"M110 215 L110 240 L620 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M280 240 L280 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bf-ah-phosphor)\"></path><path d=\"M450 240 L450 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bf-ah-phosphor)\"></path><path d=\"M620 240 L620 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bf-ah-phosphor)\"></path><text x=\"450.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">três máquinas, uma imagem</text></svg>", "caption": "Configurada no boot, cada máquina é construída no dia em que liga, com o que o repositório tiver naquele dia. Assada, a construção aconteceu uma vez, antes de qualquer uma delas existir.", "same": ["packer build", "boot"]}
```

Eis a diferença no notebook, com contêineres no papel de máquinas. O primeiro comando é uma partida
frita: Ubuntu limpo, depois apt. O segundo parte de `shop-web:1.0.1`, a imagem que esta aula
constrói nas duas próximas seções, então no seu computador ele funciona depois que você a construir
lá. Os dois usam o Docker como a aula 18 o instalou:

```
ana@laptop:~/shop/image$ time docker run --rm ubuntu:24.04 sh -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null && nginx -v'
debconf: delaying package configuration, since apt-utils is not installed
nginx version: nginx/1.24.0 (Ubuntu)

real	0m9.069s
user	0m0.012s
sys	0m0.022s
```

```
ana@laptop:~/shop/image$ time docker run --rm shop-web:1.0.1 nginx -v
nginx version: nginx/1.24.0 (Ubuntu)

real	0m0.358s
user	0m0.014s
sys	0m0.023s
```

Um contêiner não é uma máquina virtual, e um boot de verdade soma o próprio tempo aos dois. O que os
dois comandos mostram é a parte que fritar acrescenta: o primeiro passou a partida baixando e
instalando, e o segundo não tinha nada a fazer além de rodar. **A instalação também exige que o
repositório esteja acessível naquele momento.** Uma máquina frita que liga enquanto o espelho de
pacotes está lento, ou fora do ar, liga devagar ou não liga, e o momento em que mais máquinas ligam
de uma vez é o momento em que a loja está mais cheia.

Assar leva tudo isso para a hora do build, onde uma falha interrompe um build e não um lançamento.
E completa o que a aula 1 chamou de **infraestrutura imutável**: uma máquina ligada a partir de uma
imagem é a imagem, e uma mudança significa uma imagem nova e uma máquina nova, nunca uma edição.
Nada configura a máquina em execução, então não há nada que possa derivar.

**O custo de assar** é um build a cada mudança, e uma imagem guardada para cada versão. Um erro de
digitação numa página vira uma imagem nova, não uma edição de uma linha. E nem tudo pertence à
imagem:

| | na imagem | no boot |
|---|---|---|
| pacotes e suas versões | sim | |
| configuração igual em todo lugar | sim | |
| qual ambiente é este, o endereço do banco | | sim |
| senhas e chaves | | sim, lidas de um cofre de segredos (aula 12) |

A fronteira fica entre o que é igual em toda cópia e o que muda de uma cópia para outra. Uma imagem
com a senha do banco dentro é uma senha em toda cópia de um arquivo, legível por qualquer um que
consiga ligar a imagem.
