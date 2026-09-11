---
title: Uma máquina, muitos sites
version: 1
---

O jeito mais barato de pôr um site na internet é pô-lo numa máquina que já roda várias centenas de
outros. Isso é hospedagem compartilhada, e foi a única opção acessível durante a maior parte da vida
da web.

Funciona por causa de um cabeçalho que você viu na aula seis. Uma máquina, um endereço, e o `Host`
decidindo qual dos sites nela você pediu — o arranjo que transformou um endereço em quantos sites
alguém quisesse.

## O que você recebe

Uma conta, uma pasta e um painel de controle.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma máquina carregando várias centenas de sites. Cada conta tem a própria pasta e o próprio nome, e o processador, a memória e o endereço são divididos entre todos.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">uma máquina, um endereço</text> <rect x=\"40\" y=\"70\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"115\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sua pasta</text> <text x=\"115\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">seunome.com</text> <rect x=\"202\" y=\"70\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"277\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um vizinho</text> <text x=\"277\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">umaloja.com</text> <rect x=\"364\" y=\"70\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"439\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um vizinho</text> <text x=\"439\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">um-blog.net</text> <rect x=\"526\" y=\"70\" width=\"154\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"603\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e mais 300</text> <text x=\"603\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">todos neste endereço</text> <rect x=\"40\" y=\"134\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">dividido: o processador, a memória, o endereço, as versões de software</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o cabeçalho `Host` da aula seis é o que separa os sites</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e nada impede um vizinho ocupado de tomar quase toda a máquina</text> </svg>", "caption": "Sua própria pasta e seu próprio nome. Tudo que está embaixo é de todo mundo."}
```

Dentro da pasta você põe arquivos. O servidor web já está rodando, configurado por outra pessoa, e
serve o que estiver na sua pasta sob o seu nome. Um banco de dados é fornecido, em geral um, com
limite de tamanho. E-mail do seu domínio costuma vir incluído. Um certificado é emitido e renovado
para você, e é por isso que este ainda é o caminho mais rápido de *comprei um domínio* até *está no
ar*.

O que você **não** recebe é a máquina. Você não instala software, não escolhe a versão de nada, não
muda a configuração do servidor web além do que o painel expõe, e não vê o que mais está rodando.

## O que de fato é dividido

Esta é a parte que vale entender, porque ela decide todos os modos de falha.

**O processador e a memória** são divididos, então um vizinho sob carga súbita deixa seu site lento.
Não há alocação que seja sua; há uma máquina, e quem estiver mais ocupado fica com a maior parte
dela. Este é o problema do vizinho barulhento, e é a queixa mais comum sobre hospedagem
compartilhada.

**O endereço** é dividido, o que importa mais do que parece. Se um vizinho manda spam ou serve
malware, o endereço ganha reputação, e essa reputação fica colada no seu e-mail e às vezes no seu
site.

**As versões de software** são divididas. Quando o provedor atualiza o runtime da linguagem, todo
mundo atualiza. Você vai ser avisado, e a data não vai ser sua.

**Os limites também são divididos**, que é o que ninguém espera. Muitos painéis contam coisas por
conta — processos, conexões simultâneas, consultas ao banco — e um site que fica popular não fica
mais lento, ele é **cortado**, com uma página de erro enquanto a máquina fica ociosa.

## Como os arquivos chegam lá

Merece uma seção porque é onde a hospedagem compartilhada colide com tudo o que o resto deste curso
implica.

Os caminhos tradicionais são um **gerenciador de arquivos no navegador** e o **FTP** ou o sucessor
cifrado dele. Os dois movem arquivos da sua máquina para a pasta, um envio por vez, e os dois
servem perfeitamente para um site de dez páginas.

Nenhum dos dois é uma publicação. Não há registro do que mudou, não há como voltar à versão de
ontem, e não há como duas pessoas terem certeza de estar olhando a mesma coisa. O site vira o que a
última pessoa enviou, e a única cópia da verdade está no servidor.

Painéis melhores hoje oferecem um caminho a partir de um repositório — um botão que puxa de um ramo,
ou uma conta de shell para onde você empurra. Se você está escolhendo um host compartilhado e
pretende seguir trabalhando no site, esse recurso vale mais que qualquer número da página de preços.

## As variantes, nomeadas

Três arranjos ficam ao redor da hospedagem compartilhada e são vendidos como se fossem categorias
diferentes.

**Hospedagem gerenciada para uma plataforma** — mais comumente para o sistema de conteúdo que roda
uma fatia enorme da web — é hospedagem compartilhada com aquela plataforma pré-instalada, atualizada
para você, e com o resto trancado. Conveniente, e agora você está no calendário de atualização de
outra pessoa também para a aplicação, além da máquina.

**Hospedagem revendedora** é uma conta compartilhada dividida em várias, para alguém vender
hospedagem aos próprios clientes. Os limites acima valem, repartidos de novo.

**Hospedagem em nuvem** na página de preços de um provedor compartilhado geralmente quer dizer o
mesmo produto em hardware melhor com outro nome. Vale ler o que de fato está incluído em vez da
categoria em que está arquivado, porque nesta parte do mercado as palavras são marketing e os
limites são a especificação.

## No que ela é genuinamente boa

Seria fácil ler o acima como um aviso. Não deveria ser. Hospedagem compartilhada é a resposta certa
mais vezes do que quem constrói coisas gosta de admitir.

Ela é barata o bastante para ser um detalhe. Não exige conhecimento que você já não tenha depois
deste curso. Outra pessoa aplica as atualizações do sistema operacional, que é o trabalho mais
negligenciado por quem o assume. E para o número enorme de sites que são algumas páginas e um
formulário, nenhuma das limitações acima jamais será alcançada.

O resumo honesto: se o seu site é conteúdo, e o tráfego é de tamanho humano, isto é uma escolha
pensada em vez de um compromisso.

## Quando sair

Quatro sinais, e cada um é sobre um limite e não sobre ambição.

**Você precisa de algo que o painel não oferece** — uma versão de linguagem, um trabalhador em
segundo plano, uma tarefa agendada, um software.

**Você está batendo nos limites da conta** em vez da capacidade da máquina. O indício é um erro num
número consistente de visitantes em vez de uma lentidão gradual.

**Os vizinhos são o problema** e o provedor não diz quem nem move você.

**Você precisa publicar do jeito que o resto deste curso implica** — a partir de um repositório, de
forma repetível, com um caminho de volta. Painéis que esperam que você envie arquivos à mão tornam
isso possível e desagradável.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro sinais específicos de que é hora de deixar a hospedagem compartilhada: precisar de algo que o painel não oferece, bater em limites da conta em vez da capacidade, vizinhos que o provedor não move, e precisar publicar a partir de um repositório.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">você precisa de algo que o painel não oferece</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">você bate num limite da conta, não na capacidade da máquina</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">os vizinhos são o problema e ninguém vai mover você</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">você precisa publicar a partir de um repositório, de forma repetível</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">nenhum destes é *eu cresci demais*, que é a razão que as pessoas dão</text> </svg>", "caption": "Quatro sinais que você vai reconhecer. Até um deles chegar, a atenção rende mais em outro lugar."}
```

Nenhum desses é *eu cresci demais para isto*, que é a razão que as pessoas costumam dar. Eles são
específicos e você vai reconhecê-los, e até um deles chegar o dinheiro e a atenção rendem mais no
que o site faz.
