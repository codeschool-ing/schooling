---
title: O que o HTTPS dá, e o que não dá
version: 1
---

**HTTPS é HTTP dentro de uma conexão TLS, e o TLS dá três coisas: ninguém no caminho consegue ler o
tráfego, ninguém no caminho consegue alterá-lo, e o navegador sabe que está falando com o servidor que o
endereço nomeia.** A terceira é a que as pessoas esquecem. Um certificado assinado por uma autoridade em
que o navegador confia é a prova de que `planner.example` é `planner.example`, e sem ele o Wi-Fi de um
café poderia responder no lugar dele.

O que o HTTPS **não** dá é qualquer afirmação sobre o próprio site. Uma página cheia de scripts injetados
é servida em HTTPS tão bem quanto uma limpa; um cadeado diz que a conexão é privada, não que o que veio
por ela é seguro. O resto desta aula é sobre a segunda metade: cabeçalhos que dizem ao navegador o que a
página tem permissão de fazer.

## Três regras que vêm disso

- **Todo recurso em HTTPS, sem exceção.** Uma página carregada em HTTPS que puxa um script em HTTP simples
  entregou esse script a qualquer um na rede; os navegadores bloqueiam esse **conteúdo misto** para scripts
  e estilos, e avisam sobre o resto.
- **Os cookies que importam são `Secure`**, como a aula 6 deixou os do planner, para nunca viajarem sem
  TLS.
- **A primeira visita é a fraca.** Quem digita `planner.example` chega primeiro em `http://`, e um
  redirecionamento para HTTPS pode ser interceptado antes de acontecer. O servidor fecha essa brecha com um
  cabeçalho, o `Strict-Transport-Security`, que diz ao navegador para usar HTTPS neste site e nunca mais
  perguntar.

Eis esse cabeçalho num site de verdade, o nodejs.org, de onde você baixou o Node:

```
ana@dev:~/planner$ curl -s -o /dev/null -D - https://nodejs.org/ | grep -i strict-transport-security
strict-transport-security: max-age=31536000; includeSubDomains; preload
```

O `max-age=31536000` é um ano, em segundos; o `includeSubDomains` cobre todo nome abaixo dele; o `preload`
pede para ser embutido nos próprios navegadores, para nem a primeiríssima visita passar por HTTP.

## O planner, aqui e quando publicado

O `http://localhost` é o único endereço que os navegadores tratam como seguro sem TLS: cookies `Secure`
funcionam ali, e é por isso que a aula 6 pôde usá-los. O HSTS em HTTP simples é ignorado, então os
servidores de desenvolvimento do planner não o mandam. **HTTPS, certificados e HSTS são definidos onde o
site é publicado**, pelo host ou pelo servidor na frente dos arquivos, e a aula 4 de `front-delivery`
cobre isso. O que esta aula acrescenta é a parte que viaja com o site, seja quem for que o hospede: a
Content Security Policy dele e os cabeçalhos em volta.
