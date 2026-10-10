---
title: Qual, e onde
version: 1
---

São três protocolos, e não são três respostas para a mesma pergunta. **O OAuth 2.0 trata de acesso a
uma API; o OpenID Connect e o SAML tratam de autenticar uma pessoa.** A tabela os põe lado a lado:

| | OAuth 2.0 | OpenID Connect | SAML 2.0 |
|---|---|---|---|
| a pergunta que responde | este cliente pode chamar esta API, dentro deste escopo? | quem entrou neste cliente? | quem entrou nesta aplicação? |
| o que entrega | um access token, para a API | um ID token, para o cliente, mais o access token do OAuth | uma asserção XML assinada, para a aplicação |
| formato | não fixo; muitas vezes um JWT | JWT | XML com assinatura XML |
| como viaja | redirecionamentos, depois uma requisição direta a `/token` | igual | redirecionamentos e um formulário que o navegador envia |
| onde você o encontra | um app chamando o Google Drive, o GitHub ou uma API de pagamento em nome de um usuário; serviços chamando uns aos outros com client credentials | "Entrar com o Google", "Entrar com a Microsoft", a entrada da maioria dos apps web e de celular novos | funcionários de uma empresa entrando nas ferramentas que ela compra, pelo provedor de identidade da empresa |

Eles também se encontram num lugar. Um provedor de identidade corporativo em geral fala SAML e
OpenID Connect, e um produto vendido a empresas tende a suportar os dois, porque cada cliente chega
com um ou com o outro.

## Como é um primeiro emprego

**Você não vai escrever um servidor de autorização, e não deve.** O trabalho é integrar com um que
outra pessoa roda. Em geral é um provedor de identidade hospedado, como Auth0, Okta, Microsoft Entra
ID, Google ou AWS Cognito, ou o Keycloak onde a empresa roda o seu; ele é dono das senhas, do
segundo fator, das telas de consentimento e das chaves de assinatura. A sua aplicação fala com ele
por uma biblioteca da sua linguagem, certificada onde existe certificação (a OpenID Foundation
lista as certificadas), que roda o fluxo e faz cada conferência desta lição em código que milhares
de outros projetos já testaram.

O que sobra para você é configuração e julgamento, e é onde as integrações dão errado. A revisão de
uma faz estas perguntas, e cada uma tem resposta numa seção desta lição:

| pergunta | a seção |
|---|---|
| Todo `redirect_uri` está cadastrado exatamente, sem curinga? | O fluxo authorization code |
| Todo cliente usa PKCE com `S256`, e envia e confere o `state`? | PKCE |
| Cada cliente pede o mínimo de escopos de que precisa, e lê o `scope` que recebeu? | Escopos e consentimento |
| O app confere assinatura, `iss`, `aud`, `exp` e `nonce` do ID token, e nunca autentica ninguém com um access token? | OpenID Connect |
| Os refresh tokens são rotacionados, guardados num servidor ou no armazenamento da plataforma, e o reuso gera alerta? | Refresh tokens |
| O segredo de cada cliente máquina está num cofre de segredos, com escopo mínimo, um cliente por trabalho? | Client credentials |
| Os grants implicit e password estão desligados? | O que saiu |
| O SAML é tratado por uma biblioteca mantida que confere audiência, horários e reenvio? | SAML |

O `idp.py` foi para ler. Quando chegar o dia de autenticar pessoas de verdade, o servidor de
autorização é produto de outra pessoa, as conferências rodam na biblioteca de outra pessoa, e a sua
parte é acertar as perguntas acima.
