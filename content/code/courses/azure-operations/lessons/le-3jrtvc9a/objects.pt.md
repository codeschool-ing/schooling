---
title: Três tipos de objeto, e as duas configurações que os mantêm
version: 1
---

**Um Key Vault guarda três tipos de objeto**, e a diferença entre eles é o que o cofre deixa você fazer com cada um:

| objeto | o que é | o que dá para fazer com ele |
|---|---|---|
| **segredo** | qualquer valor de até 25 KB: uma senha, uma connection string, uma chave de API | lê-lo de volta, inteiro |
| **chave** | uma chave criptográfica, RSA ou de curva elíptica | pedir ao cofre que assine, verifique, cifre ou decifre com ela; a parte privada nunca sai |
| **certificado** | um certificado X.509 com a sua chave | emitir, renovar e ler a parte pública; o cofre pode renová-lo com uma autoridade certificadora |

A diferença que mais importa é a segunda linha. **Um segredo é entregue; uma chave é usada no lugar.** Uma aplicação que lê um
segredo fica com ele na memória, e quem comprometer a aplicação também fica. Uma aplicação que assina com uma chave manda os
dados ao cofre e recebe uma assinatura de volta, e a chave em si não pode ser roubada dela. O nível `premium` guarda chaves em
módulos de segurança de hardware; o `standard`, o da loja, guarda em software.

Duas configurações decidem se um cofre apagado, ou um segredo apagado, pode voltar:

- **exclusão reversível**: um cofre ou objeto apagado é mantido por um período de retenção, de 7 a 90 dias, e pode ser
  recuperado. Vem ligada por padrão em cofres novos e não pode ser desligada;
- **proteção contra purga**: durante esse período, **ninguém pode purgar**, ou seja, apagar de vez, nem um Owner. Uma vez
  ligada, não pode ser desligada.

A proteção contra purga parece um incômodo e é o ponto. Sem ela, alguém com uma conta de administrador comprometida apaga o
cofre e depois o purga, e toda chave que cifrava os dados da loja se vai sem volta. Com ela, o pior que dá para fazer espera
90 dias para alguém perceber. A lição 16 listou um cofre sem ela como achado; a próxima seção conserta isso em Bicep.
