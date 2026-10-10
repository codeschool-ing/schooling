---
title: Onde quem testa ainda o encontra
version: 1
---

**O SOAP é velho e não foi embora.** Ninguém que começa uma API pública hoje o escolhe, e um curso
que ensinasse só APIs novas deixaria você despreparado para os sistemas que movem dinheiro e
impostos. Esses foram construídos nos anos 2000, quando o SOAP era o jeito padrão de os programas
de duas empresas conversarem, e continuam funcionando. Trocar uma integração que funciona e que um
órgão regulador aprovou custa mais do que mantê-la, então ela é mantida.

## Três lugares onde ele vive

- **Governo.** No Brasil, toda nota fiscal eletrônica de mercadoria, a **NF-e**, é mandada aos web
  services da secretaria da fazenda do estado como uma mensagem SOAP, e a nota dentro dela é XML
  assinado com um certificado digital. O eSocial, o sistema federal em que os empregadores
  informam suas obrigações trabalhistas e tributárias, também recebe XML assinado por web services
  SOAP, então toda empresa com funcionários manda mensagens SOAP, saibam disso os desenvolvedores
  dela ou não.
- **Bancos e seguradoras.** Redes de pagamento, consultas de crédito e sistemas de apólices muitas
  vezes ficam atrás de uma interface SOAP que o próprio app do banco nunca vê. O app fala JSON com
  o backend do banco, e o backend fala SOAP com o sistema central.
- **Grandes empresas, por dentro.** Companhias aéreas, operadoras de telefonia e varejistas ligaram
  seus sistemas por SOAP durante duas décadas. Um app novo numa delas muitas vezes é uma camada JSON
  por cima desses serviços.

Esse último padrão é onde quem começa em testes tem mais chance de encontrar o SOAP: **atrás de uma
API que você está testando, e não na sua frente.** O boxoffice poderia funcionar assim. Um teatro em
São Paulo vende um serviço, e cada ingresso precisaria de uma nota do web service de notas da
prefeitura, que o boxoffice chamaria depois do pagamento. O celular nunca vê essa chamada; o pedido
falha ou dá certo por causa dela.

## O que isso significa para um teste

Duas coisas são diferentes ao testar um serviço como o da NF-e, e as duas dão forma a esta lição.

**Você não consegue chamar o verdadeiro do seu notebook.** Ele pede um cadastro da empresa e um
certificado digital, e um erro em produção emite um documento fiscal de verdade. Os serviços da
NF-e têm um segundo ambiente, o de *homologação*, onde uma nota não tem valor fiscal, justamente
para que as integrações possam ser testadas. Até esse pede o certificado. Por isso a seção 04 dá a
você um substituto seu, com a mesma forma: um endereço, uma operação, um WSDL e falhas.

**Os testes interessantes são sobre a falha.** Um serviço que emite notas quando tudo está certo é a
metade fácil. O que ele responde quando o CPF está curto, quando falta um campo, quando o nome da
operação está errado? Ele culpa o cliente ou a si mesmo? E o que quem chama faz com cada resposta?
As primeiras perguntas são desta lição; a última, uma dependência falhando de propósito, é aquilo
para que a lição 11 constrói um servidor mock.
