---
title: O tenant
version: 1
---

Na fintech, a Joana tinha escrito o serviço de login ela mesma: uma tabela de usuários, um hash de
senha, um token. Identidade era um componente que ela projetava. Na Serra Alta é algo que ela
herdou, e é maior do que qualquer sistema que ela olhou até agora. **Um tenant da Microsoft é a única
integração que todo sistema da empresa já tem com cada pessoa dela**, e a maior parte das suas
consequências é decidida por gente que não se vê como integradora.

Um tenant é a instância de uma organização na nuvem da Microsoft: seus usuários e grupos, seus
domínios, suas licenças e a lista de aplicações em que ela confia. O serviço de diretório e de login
dentro dele é o Microsoft Entra ID, que se chamava Azure Active Directory até a Microsoft renomeá-lo
em 2023, e você vai encontrar os dois nomes no mesmo documento por anos. As caixas do Exchange, o
Teams, o SharePoint, a Power Platform e o Business Central online autenticam seus usuários por ele.
Qualquer outra aplicação que aceite um dos dois padrões comuns de login delegado, SAML e OpenID
Connect, também pode.

O tenant da Serra Alta foi criado em 2017 e tem cerca de 2.150 contas. Nem todo mundo tem uma: a
maior parte do pessoal do chão de fábrica usa terminais compartilhados e não aparece em diretório
nenhum.

## Quem confia no tenant

Quando uma aplicação confia no tenant, a pessoa faz login uma vez, no Entra ID, e a aplicação aceita
o token que recebe em vez de pedir uma senha própria. Isso é single sign-on, e na Serra Alta ele
alcança mais ou menos metade do parque.

| sistema | como os funcionários entram | o que desativar a conta no Entra faz ali |
|---|---|---|
| Microsoft 365 (e-mail, Teams, SharePoint) | Entra ID | bloqueia todo login novo |
| Salesforce | SAML, pelo Entra ID, desde 2020 | bloqueia logins novos; o usuário do Salesforce e a licença dele continuam |
| Rota | OpenID Connect, pelo Entra ID | bloqueia logins novos |
| Portal B2B, retaguarda interna | OpenID Connect, pelo Entra ID | bloqueia logins novos |
| SAP ECC | usuário e senha próprios | nada |
| Documentum | contas próprias | nada |
| Coleta | perfil de usuário próprio no IBM i | nada |
| Business Central | o tenant antigo da Mantiqueira | nada: é outro tenant |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l03-identity\" aria-label=\"O tenant da Serra Alta, Entra ID com cerca de 2.150 contas, fica no meio. À esquerda, a folha de pagamento operada por um fornecedor externo só chega a ele por um chamado do RH, uns três dias úteis atrasado. À direita, quatro sistemas autenticam pelo tenant: Microsoft 365, Salesforce por SAML, Rota por OpenID Connect e a retaguarda do Portal B2B. Embaixo, três sistemas mantêm senhas próprias e o tenant não alcança nenhum deles: SAP ECC, Documentum e Coleta. No canto inferior direito, dentro do tenant antigo da Mantiqueira, o Business Central e seus 41 usuários, cada um com uma segunda identidade.\"><defs><marker id=\"l03-identity-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-identity-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15.0\" y=\"108.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"123.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">folha de pagamento</text><text x=\"85.0\" y=\"136.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fornecedor externo</text><path d=\"M157.0 130.0 L233.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-identity-es-ah-amber)\"></path><text x=\"195.0\" y=\"93.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">chamado do RH,</text><text x=\"195.0\" y=\"106.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">~3 dias úteis</text><rect x=\"235.0\" y=\"98.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"116.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tenant da Serra Alta</text><text x=\"320.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Entra ID</text><text x=\"320.0\" y=\"143.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~2.150 contas</text><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">entram pelo tenant</text><rect x=\"505.0\" y=\"33.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft 365</text><path d=\"M406.0 111.2 L503.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><rect x=\"505.0\" y=\"83.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Salesforce, SAML</text><path d=\"M406.0 123.8 L503.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><rect x=\"505.0\" y=\"133.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Rota, OpenID Connect</text><path d=\"M406.0 136.2 L503.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><rect x=\"505.0\" y=\"183.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">retaguarda do Portal B2B</text><path d=\"M406.0 148.8 L503.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><text x=\"240.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">senhas próprias: o tenant não alcança nenhum</text><rect x=\"25.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"90.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"175.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"240.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Documentum</text><rect x=\"325.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"390.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta, IBM i</text><rect x=\"490.0\" y=\"250.0\" width=\"220.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tenant antigo da Mantiqueira</text><rect x=\"510.0\" y=\"293.0\" width=\"180.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"311.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"600.0\" y=\"324.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">41 usuários, 2ª identidade</text></svg>", "caption": "Quem o tenant alcança. Desativar uma conta fecha a coluna da direita e deixa os quatro sistemas de baixo para chamados separados.", "same": ["Business Central", "Coleta, IBM i", "Documentum", "Entra ID", "Microsoft 365", "Rota, OpenID Connect", "SAP ECC", "Salesforce, SAML"]}
```

Duas coisas nessa tabela merecem uma segunda leitura.

A primeira é a coluna da direita para o Salesforce. **Single sign-on remove uma senha; não remove uma
conta.** O registro de usuário no Salesforce continua existindo depois que a pessoa sai. Continua
ocupando uma licença paga e sendo dono de registros e relatórios, e qualquer outra coisa que se
autentique como aquele usuário, como um token de API emitido no mês passado, não é tocada pelo
diretório. A outra metade do trabalho é o provisionamento: o tenant criando, alterando e desativando
a conta dentro da própria aplicação. O Entra ID faz isso para aplicações que suportam SCIM, um padrão
aberto feito exatamente para isso, e a Microsoft entrega conectores de provisionamento prontos para
produtos SaaS comuns. A Serra Alta configurou o single sign-on do Salesforce e nunca configurou o
provisionamento, então a Talita Gomes desativa quem sai à mão, quando alguém se lembra de avisá-la.

A segunda são as quatro linhas de baixo. Três sistemas mantêm senhas próprias, e são os três mais
antigos: **os sistemas a que quem sai tem mais chance de continuar com acesso são os que guardam o
dinheiro e o leite.** O time do Edson Prado já planejou single sign-on para o SAP duas vezes e adiou
duas vezes, nas duas por causa de um projeto que parecia mais urgente.

## Quem entra, quem muda, quem sai

Toda conta em cada um desses sistemas é criada, alterada e encerrada por algum processo, e o pessoal
de identidade chama os três casos de joiners, movers e leavers. Na Serra Alta, a fonte da verdade
sobre quem trabalha lá é a folha de pagamento, que um fornecedor externo opera. Nada liga a folha ao
tenant. Quando alguém sai, o RH abre um chamado para a TI, e o chamado chega em média três dias úteis
depois do último dia da pessoa.

A TI então desativa a conta no Entra, e os quatro sistemas da metade de baixo da tabela esperam
alguém abrir um segundo, um terceiro e um quarto chamado. Os auditores externos acharam o resultado
em 2025: 37 usuários ativos no SAP pertencentes a pessoas que tinham saído, cinco deles com alçada
para liberar pagamentos. Ninguém os tinha usado, e ninguém conseguiria provar isso antes da auditoria
também.

A primeira reação da Joana foi a da fintech: automatizar. A segunda, melhor, foi desenhar. **A saída
de uma pessoa é uma integração com prazo**: um evento num sistema que precisa chegar a outros oito, e
que falha em silêncio quando chega a sete. Desenhada assim, ela tem as mesmas perguntas de qualquer
integração das aulas 9 a 11. Qual é o evento de origem, quem o consome, o que acontece quando um
consumidor o perde, e como alguém ficaria sabendo?

Quem muda de área é pior, porque nada falha. Uma compradora que vai de compras para vendas mantém as
autorizações de compras, a menos que alguém as remova, e ganha as de vendas por cima. Depois de
mudanças suficientes, uma funcionária antiga consegue criar um pedido de compra, confirmar que a
mercadoria chegou e liberar o pagamento. É a combinação que a segregação de funções existe para
impedir, e ela é montada um pedido sensato de cada vez.

## Grupos como autorização

Dentro do tenant, o acesso é concedido sobretudo por grupos. Um time do Teams tem por trás um grupo
do Microsoft 365, um site do SharePoint dá permissões a grupos, e uma aplicação que confia no tenant
pode receber os grupos da pessoa no token de login e mapeá-los para os próprios papéis. Grupos também
podem ser dinâmicos: a participação é uma regra sobre atributos do diretório, como "departamento
igual a Qualidade", recalculada quando os atributos mudam.

Isso é cômodo, e tem uma consequência que surpreendeu a Cláudia Mendes. Uma técnica de laboratório
em Barbacena não conseguia abrir o site do SharePoint do time da qualidade, porque o campo de
departamento da conta dela dizia "Produção". O RH tinha digitado ali o centro de custo dela, que era
o que o campo guardava para todo mundo contratado naquele ano. **Quando um grupo concede acesso, o
dado que decide quem participa dele é dado de segurança**, e quem o mantém está tomando decisões de
acesso sem ter sido avisado. Aqui, era quem preenchia o formulário de contratação.

## Uma empresa, dois tenants

A Mantiqueira veio com o próprio tenant, no próprio domínio. Em 2022 as caixas de e-mail e o Teams
dela foram para o tenant da Serra Alta, e o pessoal recebeu contas da Serra Alta. O Business Central
não foi. Um ambiente do Business Central online pertence a um tenant e autentica os usuários por ele,
então as 41 pessoas que usam o ERP da Mantiqueira ainda entram com as contas antigas da Mantiqueira.
Essas contas, portanto, ainda existem, ainda licenciadas, num tenant cujo processo de desligamento é
o Felipe Arruda se lembrar.

Cada uma dessas 41 pessoas tem duas identidades, e cada uma que sai precisa ser encerrada duas vezes,
por duas pessoas diferentes. Levar o ERP para o tenant da Serra Alta é um projeto com plano e
indisponibilidade próprios, e ninguém o agendou. Ele entra na lista das coisas que a aquisição deixou
pela metade, e a última seção desta aula volta a ele, porque qualquer integração com o Business
Central também vai se autenticar naquele tenant antigo.

## Onde os documentos moram de verdade

O tenant também é onde ficam os arquivos da Serra Alta. O Teams guarda os arquivos de um canal num
site do SharePoint e os arquivos compartilhados num chat no OneDrive de quem enviou, então os cerca
de 400 times da empresa são, entre outras coisas, 400 bibliotecas de documentos que ninguém projetou.

Oficialmente, os documentos da qualidade moram no Documentum: os procedimentos operacionais padrão,
os certificados de laboratório e os relatórios de auditoria, cada um com uma versão aprovada (a aula
5 trata do que isso significa). Na prática, as fábricas guardam cópias nos canais do Teams, porque
uma pasta do Teams está a dois cliques e o Documentum a seis. Na auditoria FSSC 22000 de 2025, o
auditor achou um procedimento de pasteurização já substituído, impresso a partir do canal do time de
Barbacena e colado ao lado do pasteurizador. Ele diferia do aprovado em uma única temperatura.

**A cópia de um documento controlado é um documento não controlado.** Proibir o Teams não resolveria
isso, e levar tudo para o SharePoint sem o fluxo de aprovação também não. A resposta do arquiteto é
decidir qual sistema é o registro de cada tipo de documento e fazer o outro apontar para ele em vez
de guardar uma cópia. A aula 5 retoma esse assunto.
