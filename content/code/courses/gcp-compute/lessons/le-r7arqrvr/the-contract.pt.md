---
title: O contrato entre um contêiner e o Cloud Run
version: 1
---

A primeira coisa a desaprender sobre o Cloud Run é que ele roda servidores. **Ele roda contêineres
que respondem requisições, e os liga e desliga conforme as requisições chegam e vão embora.** Você
nunca vê uma máquina, nunca escolhe uma, e nunca fica sabendo qual rodou o seu código. O que você
ganha em troca é uma lista curta de promessas que o seu contêiner precisa cumprir, e se ele cumprir,
o Cloud Run cuida do resto: o endereço, o certificado, o balanceamento, o número de cópias, e as
cópias que ninguém precisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um cliente chega ao front end do Cloud Run por HTTPS num endereço estável. O front end, que o Google opera, cuida do certificado, da escala e do roteamento, e repassa cada requisição como HTTP puro à porta em PORT dentro de uma instância de contêiner. O contêiner, que você escreve, precisa escutar em 0.0.0.0 nessa porta, não guardar estado, responder dentro do tempo limite e parar em até dez segundos depois do SIGTERM.\"><defs><marker id=\"l8c-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"110\" width=\"110\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"71.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um cliente</text><path d=\"M126 135 L176 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8c-ah)\"></path><text x=\"151\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTTPS</text><rect x=\"176\" y=\"40\" width=\"210\" height=\"220\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"281\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o Google opera isto</text><rect x=\"196\" y=\"80\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">front end</text><text x=\"281.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um endereço estável</text><rect x=\"196\" y=\"136\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">o certificado</text><rect x=\"196\" y=\"178\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">quantas instâncias</text><rect x=\"196\" y=\"220\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"281.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">roteamento às revisões</text><path d=\"M410 30 L410 280\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"410\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">o contrato</text><path d=\"M366 102 L450 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8c-ah)\"></path><text x=\"388\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTTP</text><text x=\"388\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">$PORT</text><rect x=\"450\" y=\"40\" width=\"254\" height=\"220\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"577\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">você escreve isto</text><rect x=\"470\" y=\"80\" width=\"214\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"577.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o seu contêiner</text><text x=\"577.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0.0.0:$PORT</text><text x=\"477\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não guarda estado entre requisições</text><text x=\"477\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">responde dentro do tempo limite</text><text x=\"477\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">registra uma linha JSON por entrada</text><text x=\"477\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">para em até 10 s após o SIGTERM</text></svg>", "caption": "A linha entre as duas metades é o contrato. Tudo à esquerda é do Google; tudo à direita é seu, e roda igual num laptop.", "same": ["front end"]}
```

## O que o contêiner promete

O Google chama isso de **contrato de runtime do contêiner**, e cinco partes dele moldam todo
programa desta lição:

1. **Escutar na porta de `PORT`**, em todas as interfaces, `0.0.0.0`. O Cloud Run define a
   variável, 8080 a menos que você mude, e manda as requisições para lá. Um servidor que escuta em
   `127.0.0.1` não atende ninguém, porque as requisições chegam de fora do loopback do contêiner.
2. **Subir rápido, e avisar escutando.** Uma instância não recebe requisições até alguma coisa
   escutar na porta; a sondagem de inicialização padrão do Cloud Run é exatamente essa verificação.
   Um programa que passa um minuto carregando antes de abrir a porta é um minuto de cada partida a
   frio.
3. **Responder cada requisição dentro do tempo limite**, cinco minutos se nada for configurado, e
   no máximo sessenta. A requisição é a unidade de trabalho: um serviço que responde na hora e
   continua trabalhando em segundo plano depende de CPU que talvez não receba, como a lição 11
   explica.
4. **Não guardar nada que precise sobreviver.** O sistema de arquivos aceita escrita, mas vive na
   memória da instância e some com ela; a própria memória acaba no momento em que o Cloud Run
   decide que a instância está ociosa. Estado vai para um banco, um bucket ou uma fila.
5. **Parar quando mandarem.** Antes de ser desligada, uma instância recebe `SIGTERM` e tem dez
   segundos para terminar antes de ser morta com `SIGKILL`. É o tempo de concluir uma requisição em
   andamento e descarregar um log, não de começar nada novo.

Mais duas são sobre a imagem e não sobre o programa. Ela precisa ser feita para **`linux/amd64`**,
porque é isso que o Cloud Run executa; uma imagem feita num laptop Arm para Arm não sobe. E ela
precisa estar num registro que o Cloud Run consiga ler, normalmente o Artifact Registry do mesmo
projeto.

## O que o Cloud Run promete de volta

Em troca, a plataforma define algumas coisas que o seu programa pode ler e em que pode confiar.
`PORT` é uma. `K_SERVICE`, `K_REVISION` e `K_CONFIGURATION` dão nome ao serviço, à revisão e à
configuração que atendem a requisição, e é assim que uma linha de log diz de onde veio. Toda
requisição chega por **HTTPS num endereço estável**, com o certificado gerenciado para você, e
alcança o seu contêiner como HTTP puro em `PORT`. E tudo que o programa escreve na saída padrão ou
na saída de erro vai para o **Cloud Logging**, com cada objeto JSON numa linha lido como uma
entrada estruturada.

**Nada disso precisa do Google para ser testado.** Um contêiner que cumpre o contrato roda no seu
laptop com `docker run` exatamente como vai rodar no Cloud Run, e as próximas duas seções montam um
e o rodam. O que precisa do Google, e é ensinado pela documentação dele, é tudo em volta do
contêiner: o endereço, a escala e a cobrança, assunto da seção 05.

## A imagem errada, com nome

A imagem que a maioria traz é a de um servidor pequeno que está sempre lá, como uma máquina da
lição 1 com menos para cuidar. Ela erra de três jeitos, e cada um custa o fim de semana de alguém:

- **instâncias são descartáveis**, então tudo que fica na memória entre requisições é, no máximo,
  um cache;
- **pode não haver nenhuma**, então a primeira requisição depois de uma hora quieta espera uma
  subir;
- **pode haver cem**, então tudo que pressupõe uma cópia só, um contador na memória ou um arquivo
  no disco local, fica errado no momento em que o tráfego chega.

Um programa escrito para essa imagem funciona perfeitamente no teste único do desenvolvedor e falha
em produção de um jeito que parece aleatório, porque o bug depende de qual instância a requisição
calhou de alcançar.
