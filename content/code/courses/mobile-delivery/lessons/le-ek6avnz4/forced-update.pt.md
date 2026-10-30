---
title: A atualização forçada
version: 1
---

**Uma atualização forçada é o app se recusando a seguir até a pessoa atualizá-lo, e é a única medida
que chega a todo celular, mais cedo ou mais tarde.** A liberação interrompida da lição 8 deixou 1011
celulares numa 1.5.0 que quebrava; uma versão mínima de 1.5.1, lida pelo app na abertura, põe uma tela
na frente de cada um deles na próxima vez que o abrirem. Isso só funciona se a 1.5.0 já tinha o código
que lê o mínimo. **A checagem precisa sair antes da versão que ela vai um dia recusar.**

## A decisão, em três resultados

| a versão instalada está | o que o app faz |
|---|---|
| abaixo da **versão mínima** | uma tela que não pode ser dispensada: esta versão não funciona mais, atualize para continuar |
| pelo menos na mínima, abaixo da **versão mais recente** | um aviso gentil, de vez em quando, que pode ser dispensado |
| na mais recente | nada |

Os dois números vêm de um servidor, e não do app, então podem mudar sem release. O script da próxima
seção decide exatamente isso.

## As ferramentas das próprias plataformas

O **Android** tem a API **In-App Updates** nas bibliotecas do Google Play, com dois fluxos, segundo a
documentação do Android, outubro de 2026:

- **imediato**: um fluxo em tela cheia que exige que a pessoa atualize e reinicie antes de usar o app;
  o Google Play instala a atualização e o reinicia;
- **flexível**: a atualização baixa em segundo plano enquanto a pessoa continua usando o app, e é
  instalada quando ela concorda.

O Google Play também deixa um release levar uma **prioridade de atualização**, de 0 a 5, que o app lê
para escolher entre os dois, e a API informa há quantos dias a atualização está disponível.

**O iOS não tem API equivalente.** O app compara a própria versão com um mínimo vindo do seu servidor,
e manda a pessoa à página da App Store com um link; a loja faz o resto. As diretrizes da Apple esperam
que o app continue funcionando enquanto isso se decide, então a tela forçada fica reservada a versões
de fato quebradas ou inseguras, e não para empurrar as pessoas para um recurso novo.

O **React Native** usa os fluxos das lojas por bibliotecas de cada plataforma, e acrescenta uma porta
própria: uma atualização over-the-air do bundle JavaScript, como a do Expo, chega às pessoas sem a
loja, dentro dos limites da lição 6. Ela não troca código nativo, então uma versão mínima continua
necessária para as correções que são nativas.

## Quando usar

Raramente, e de propósito: uma correção de segurança, um crash que perde dados, uma mudança no
servidor que a versão antiga não aguenta, lição 20. **Uma atualização forçada é a tela mais irritante
que um app pode mostrar**, e um app que a mostra todo mês ensina às pessoas que atualizar é um fardo, o
contrário do objetivo.
