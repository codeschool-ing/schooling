---
title: Quando uma AC erra
version: 1
---

**Cada uma das cerca de cem raízes confiáveis pode assinar um certificado para qualquer nome, então
o sistema é tão forte quanto a AC mais fraca da lista.** Essa é a falha conhecida do projeto. A
resposta, construída nos últimos quinze anos, não tenta tornar toda AC perfeita. Ela torna todo
certificado **público**, para que um errado seja visto, e torna as consequências para uma AC que se
comporta mal graves o bastante para importar.

## O que já aconteceu

- **DigiNotar, 2011.** Uma AC holandesa foi invadida e suas chaves foram usadas para emitir mais de
  quinhentos certificados fraudulentos, entre eles um para `*.google.com` que foi usado para
  interceptar o tráfego do Gmail de usuários no Irã. Isso foi percebido porque o Chrome trazia
  embutidas as chaves do próprio Google e recusou o certificado forjado. Todos os navegadores
  removeram as raízes da DigiNotar em poucas semanas, e a empresa faliu no mesmo mês.
- **Symantec, 2017.** Depois de uma série de certificados emitidos indevidamente, incluindo
  certificados de teste para domínios que ninguém havia pedido, o Google e a Mozilla decidiram deixar
  de confiar nas raízes da Symantec por etapas. A Symantec vendeu seu negócio de AC, e os
  certificados dela pararam de funcionar nos navegadores ao longo de 2018.
- **Casos menores** (TURKTRUST em 2013, CNNIC em 2015, WoSign e StartCom em 2016) terminaram em
  restrições ou remoção. O padrão é o mesmo: uma AC emite algo que não deveria, o certificado é
  achado, os programas de repositórios de confiança agem.

O caso da DigiNotar foi achado por sorte, num site cujo dono tinha fixado as próprias chaves. Os
mecanismos abaixo existem para que achar um deixe de depender de sorte.

## Certificate Transparency

A **Certificate Transparency (CT)**, RFC 6962, exige que os certificados sejam gravados em registros
(*logs*) públicos, só de acréscimo, mantidos por várias organizações independentes. Uma AC submete
cada certificado e recebe de volta um recibo assinado, um *Signed Certificate Timestamp*, que ela
embute no certificado. O Chrome exige esses recibos de todo certificado de confiança pública desde
2018, e o Safari faz o mesmo; um certificado ausente dos registros é recusado.

A consequência para um defensor é direta: **todo certificado que qualquer AC pública já emitiu para o
seu domínio pode ser listado.** Serviços de busca como o crt.sh leem os registros, e ferramentas de
monitoramento mandam um alerta quando aparece um certificado para o seu domínio que a sua equipe não
pediu. Um certificado forjado ainda pode ser emitido, mas não pode ser emitido em segredo.

## CAA: dizendo quais ACs podem emitir

Um domínio pode publicar um registro **CAA** no DNS, listando as únicas ACs autorizadas a emitir
para ele. As ACs são obrigadas a conferi-lo desde 2017 e precisam recusar quando não estão na lista.
Para a Vereda, que usa uma AC nos sites públicos, o registro seria:

```
vereda.example.  3600  IN  CAA  0 issue "letsencrypt.org"
vereda.example.  3600  IN  CAA  0 iodef "mailto:security@vereda.example"
```

A segunda linha pede que a AC avise sobre pedidos recusados. O CAA não impede uma AC comprometida
que o ignore; ele impede que ACs honestas sejam enganadas, que é o caso mais comum.

## Vidas curtas

Um certificado que vazou ou foi emitido errado é perigoso até expirar, e a revogação (aula 9) é pouco
confiável. Por isso o CA/Browser Forum vem encurtando a vida máxima dos certificados TLS públicos:
398 dias desde 2020, **200 dias a partir de março de 2026**, 100 dias a partir de março de 2027 e 47
dias a partir de março de 2029. O certificado do portal da Vereda no laboratório vai de 1º de maio a
17 de novembro de 2026, exatamente 200 dias. Vidas tão curtas só funcionam com **renovação
automática**, ACME, e esse é o efeito colateral pretendido: uma equipe que renova à mão uma vez por
ano esquece; uma equipe cujos servidores se renovam sozinhos a cada poucas semanas não esquece.
