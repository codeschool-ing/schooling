---
title: SaaS, onde o que sobra são pessoas e dados
version: 1
---

**No SaaS não há máquina, runtime nem código seu, e o que sobra é a parte de que os vazamentos são
feitos: quem tem conta, o que pode compartilhar, quais outros produtos podem entrar, e por quanto tempo
os dados ficam.** Nada nesta seção foi executado. Um produto SaaS não tem imitação neste laboratório, e
os controles abaixo são ensinados pela documentação dos produtos citados.

A imagem errada é a de que comprar SaaS compra junto a segurança do fornecedor. Compra a segurança da
**plataforma** do fornecedor, que é real e está descrita nos relatórios dele, como a aula 2 mostrou. As
configurações dentro do seu tenant são tão suas quanto uma política de bucket, e muitas vezes ficam na
ponta permissiva quando o tenant é criado, porque é isso que faz um período de teste funcionar.

## Quatro itens, e a configuração por trás de cada um

| item | a pergunta | onde fica, em dois produtos comuns |
|---|---|---|
| **contas** | todo mundo entra pelo provedor de identidade da empresa, com MFA, e sair da empresa encerra a conta? | o Microsoft 365 pelo Microsoft Entra ID; o Google Workspace pelo Admin console, ou por um provedor de identidade externo via SAML |
| **compartilhamento** | um arquivo pode ser compartilhado fora da empresa, ou com "qualquer pessoa com o link"? | as configurações de compartilhamento do SharePoint e do OneDrive; as do Drive no Admin console |
| **integrações** | um usuário pode dar a um aplicativo de terceiros acesso ao e-mail ou aos arquivos dele, clicando em "permitir"? | as configurações de consentimento de usuário do Entra ID; os controles de API para apps de terceiros no Google Workspace |
| **retenção e auditoria** | por quanto tempo os registros ficam guardados, podem ser exportados e apagados, e há um log de quem leu o quê? | as políticas de retenção e o log de auditoria, cujo detalhe depende da licença |

Cada linha é uma decisão numa tela de administração, e cada uma tem uma falha comum:

- **contas**: uma pessoa que saiu ainda entra, porque a conta do SaaS foi criada à mão e nunca ligada
  ao diretório. A conta da dani na aula 6 é a mesma falha na AWS;
- **compartilhamento**: uma pasta compartilhada com "qualquer pessoa com o link" para uma reunião e
  nunca descompartilhada. A aula 10 trata desta;
- **integrações**: um complemento de agenda que uma recepcionista aprovou em 2022, e que ainda tem
  permissão de ler toda mensagem da caixa dela;
- **auditoria**: o registro de quem leu o prontuário de um paciente só existe numa licença que a
  clínica não comprou, uma pergunta a resolver antes do incidente e não depois. O caso de 2023 da aula 2
  foi achado exatamente num registro assim.

## O que o contrato acrescenta

No SaaS o fornecedor guarda os seus dados, então dois documentos pertencem à sua lista tanto quanto
qualquer configuração. O **acordo de tratamento de dados** faz do fornecedor o que a LGPD chama de
*operador*, alguém que trata dados pessoais em nome da clínica e sob as instruções dela, e diz o que ele
pode fazer com eles. A **lista de suboperadores** nomeia as outras empresas que tocam os dados, e os
países em que estão, assunto a que a aula 17 volta.

## Fazendo as perguntas

Nada nesta lista precisa de linha de comando. Precisa da tela de administração, de uma pessoa que saiba
as respostas, e do mesmo hábito das duas últimas seções: **ler a configuração de volta e guardar a
prova**. Uma captura de tela das configurações de compartilhamento, com data, é para o SaaS o que a
transcrição de `describe-security-groups` foi para o IaaS. Produtos que reúnem essas configurações em
muitos tenants de SaaS são vendidos como *gestão de postura de segurança de SaaS* (SSPM), o parente SaaS
do assunto da aula 16.
