---
title: O que uma assinatura prova
version: 1
---

**Todo app Android e iOS é assinado, e a assinatura é a identidade dele.** Um celular se recusa a instalar
um app sem assinatura, e só aceita uma atualização quando ela é assinada pela mesma chave do app já
instalado. Essa regra é o que impede qualquer um de mandar uma "atualização" do seu app: sem a sua chave, não
dá.

As duas plataformas fazem isso de jeitos diferentes.

**O Android assina com uma chave que você cria.** Ela mora numa *keystore*, um arquivo protegido por senha,
e o certificado dela é autoassinado: nenhuma autoridade responde por ele, ele só precisa ser a mesma chave
toda vez. O Google Play acrescenta uma camada, o **Play App Signing**:

- Você assina o que envia com uma **chave de upload**, que é sua.
- O Play confere essa assinatura, a remove, e assina o app que entrega com uma **chave de assinatura do
  app** que o Google guarda.

Então a chave que os celulares veem é a do Google, e a chave que você poderia perder é só a de upload, que o
Play consegue trocar quando você pede. *Antes do Play App Signing, perder a chave queria dizer que o app
nunca mais poderia ser atualizado; ainda vale a pena não descobrir como é trocar uma.*

**O iOS assina com um certificado que a Apple emite**, por uma conta paga de Apple Developer. Um build
precisa de duas coisas: um **certificado de distribuição**, que diz quem você é, e um **perfil de
provisionamento**, que diz qual app, com quais capacidades (o push da aula 16 é uma), pode ser assinado com
ele. O Xcode cria e renova os dois, o que é parte do motivo de builds de iOS precisarem de um Mac, ou de um
serviço que tenha um. A última seção é esse serviço.
