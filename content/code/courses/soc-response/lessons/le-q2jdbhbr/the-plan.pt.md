---
title: O plano: decisões tomadas de antemão
version: 1
---

Um **plano de resposta a incidentes** é um documento curto que registra decisões para que não precisem ser
tomadas sob pressão. A maioria dos planos que falham falha não por estar errada, e sim por ser longa, não
lida, e muda sobre a única decisão que importava. O que um plano precisa resolver:

| o plano diz | a pergunta de quinta que ele responde |
|---|---|
| **o que conta como incidente**, e a escala de severidade | um login bem-sucedido depois de tentativas é incidente, e de que severidade? |
| **quem lidera**, por função, com um substituto | quem está no comando às nove da manhã? |
| **quem pode autorizar o quê**: desligar um servidor, desativar uma conta, chamar a polícia | a ana pode tirar o `files` do ar, ou precisa ser a sócia? |
| **quem precisa ser avisado, e quando**: diretoria, jurídico, o encarregado de dados | quando o advogado da empresa fica sabendo de arquivos de clientes saindo? |
| **como as pessoas são alcançadas** quando os canais normais podem estar comprometidos | se o e-mail não é confiável, como elas conversam? |
| **contatos externos**: a seguradora, uma empresa de resposta contratada, o CERT.br, a ANPD | quem de fora ajuda, e quem de fora precisa ser informado? |
| **onde a evidência fica guardada**, e com quem | para onde vão os logs com hash da aula 3 e as imagens da aula 16? |

A terceira linha é a que mais se deixa de fora e da qual mais se arrepende. **A autoridade para agir precisa
ser delegada antes do incidente**: um analista que precisa achar um diretor para aprovar o isolamento de um
servidor às duas da manhã vai esperar, e perder horas, ou agir sem autoridade, e levar a culpa pela parada. O
plano diz quais ações quem lidera a resposta pode tomar sozinho.

Mantenha o plano **curto o bastante para ser lido durante um incidente**, versione-o, dê a ele um dono, e
revise-o pelo menos uma vez por ano e depois de todo incidente relevante.
