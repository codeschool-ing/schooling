---
title: O Active Directory e o Entra ID não são a mesma coisa
version: 1
---

**O nome convida à imagem errada.** O Microsoft Entra ID se chamava Azure Active Directory até 2023, e
muita gente ainda supõe que ele é o Active Directory do escritório levado para a nuvem. Não é. São dois
diretórios diferentes, feitos para dois mundos diferentes, e uma empresa que tem os dois precisa
decidir como uma pessoa pode ser a mesma pessoa em cada um.

| | Active Directory Domain Services | Microsoft Entra ID |
|---|---|---|
| onde roda | em controladores de domínio, servidores da empresa | na nuvem da Microsoft, como serviço |
| para que foi feito | computadores numa rede: login no Windows, compartilhamentos de arquivos, impressoras | aplicações na internet: Azure, Microsoft 365, qualquer app que fale os protocolos da web |
| como prova identidade | Kerberos e NTLM, na rede local | OAuth 2.0, OpenID Connect e SAML, por HTTPS |
| como se organiza | domínios, florestas e unidades organizacionais, com group policy | um tenant plano, com grupos e unidades administrativas |
| quem entra nele | máquinas Windows na rede da empresa | dispositivos em qualquer lugar, e aplicações |

Nenhum substitui o outro numa empresa que roda os dois. O servidor de arquivos do escritório continua
perguntando ao Active Directory; o portal do Azure pergunta ao Entra ID. **A pergunta que esta lição
responde é como uma pessoa com conta no primeiro ganha uma no segundo sem ninguém digitá-la duas
vezes**, e como ela depois prova quem é para o segundo.

## Onde uma conta nasce

Todo usuário numa empresa híbrida tem uma **fonte de autoridade**: o único diretório onde a conta é
criada, alterada e desativada. Para a maioria das empresas que já rodam Active Directory, é o Active
Directory. O processo do RH cria a conta ali, quem sai é desativado ali, e o Entra ID recebe uma cópia.

Isso torna uma regra inegociável: **mude uma conta sincronizada na fonte, nunca na cópia.** Um nome
corrigido no Entra ID é sobrescrito na próxima sincronização; um usuário desativado só no Entra ID ainda
consegue entrar nas máquinas do escritório. As contas de emergência da lição 11 são a exceção
deliberada, nascidas na nuvem para não dependerem de nada no chão.

## O que viaja, e em que sentido

A sincronização copia do Active Directory para o Entra ID: usuários, grupos e as participações neles,
contatos, e, se a empresa escolher, um hash de cada senha, que a última seção desta lição pesa. Algumas
coisas podem voltar, o que se chama **writeback**: uma senha trocada na nuvem, para que uma pessoa que
redefine a sua pela página de autoatendimento do Entra ID consiga depois entrar no escritório também.

**Tudo nesta lição é lido, não executado.** A sincronização precisa de um Active Directory e de um
tenant, e um laboratório sem nenhum dos dois não consegue mostrá-la. Uma pergunta sobre o resultado é
pública, porém, e a última seção a faz ao próprio Entra ID.
