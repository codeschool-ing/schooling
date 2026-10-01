---
title: Operando uma PKI sem virar o ponto fraco dela
version: 1
---

Uma CA é um programa pequeno e uma responsabilidade grande: quem tem a chave dela pode se passar por
qualquer nome que ela cobre, diante de qualquer máquina que confie nela. As práticas que a mantêm
confiável são mais organizacionais do que técnicas, e cada uma responde a um jeito como CAs já
falharam de fato.

| prática | responde a |
|---|---|
| **raiz offline**, CA emissora online, como esta aula montou | um servidor comprometido levando a raiz junto |
| **chaves em hardware** (um HSM ou um smart card) para as CAs | uma chave copiada de um disco sem ninguém perceber |
| **uma política escrita** do que é verificado antes de assinar | uma CA assinando tudo o que recebe |
| **validade curta e renovação automática** | revogação que ninguém confere; certificados que expiram sem ninguém notar |
| **restrições de nome** em uma CA interna: só nomes sob `corp.example.com` | uma CA interna usada para se passar por sites públicos |
| **um inventário** do que foi emitido, para quê, com as datas de expiração | a queda das 3 da manhã causada por um certificado que todo mundo esqueceu |

Duas delas merecem uma segunda frase. As **restrições de nome** (*name constraints*) transformam a CA
de uma empresa, de uma chave que poderia responder por qualquer nome da internet, em uma que só
responde pelos nomes da própria empresa: instalá-la nas máquinas da equipe deixa de ser um risco para
tudo o mais que elas visitam. E o **inventário** é a falha mais comum de todas, muito mais comum do
que qualquer ataque: certificados expiram no prazo, e os serviços que param naquele dia são os que
ninguém listou.

## A confiança pública é vigiada

As CAs públicas passam por mais uma verificação: a **Certificate Transparency**. Todo certificado que
emitem é registrado em logs públicos que só aceitam acréscimos, e os navegadores rejeitam
certificados que não foram registrados. Uma empresa pode monitorar os logs para os seus próprios
domínios e descobrir em poucas horas se alguma CA, em qualquer lugar, emitiu para um dos seus nomes
um certificado que ela não pediu. É um controle de detecção, no sentido das aulas 14 a 16, aplicado à
própria PKI.
