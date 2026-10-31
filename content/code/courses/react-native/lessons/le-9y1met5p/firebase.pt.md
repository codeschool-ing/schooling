---
title: Push com o Firebase direto
version: 1
---

**O serviço do Expo é opcional.** Um app pode se registrar no FCM ele mesmo, e o servidor pode mandar pelo
Firebase Cloud Messaging sem o Expo no meio. Três motivos pelos quais se faz isso:

- **O backend já está no Firebase ou no Google Cloud**, e mais um serviço no caminho é mais uma coisa a
  vigiar.
- **Mensagens só de dados**: um push sem notificação visível, que acorda o app para sincronizar. Essa é a
  forma própria do FCM no Android, com todas as opções que ele tem.
- **Um token para tudo o que o Firebase faz**, analytics e mensagens dentro do app incluídos.

A biblioteca de costume é a `@react-native-firebase/messaging`. *O que segue vem da documentação dela e não
foi construído para este curso.* Ela precisa do `google-services.json` e do `GoogleService-Info.plist` do
projeto do Firebase no projeto, nomeados no `app.json` em `android.googleServicesFile` e
`ios.googleServicesFile`, e dos config plugins dela. O app pede o token do FCM com `messaging().getToken()`.
**No iOS, o FCM ainda passa pelo APNs**: o Firebase repassa a mensagem, usando uma chave do APNs enviada ao
console do Firebase. O servidor manda pela API HTTP v1 do FCM, autenticado como uma conta de serviço do
Google.

**A decisão é sobre o servidor, não o app.** Os dois caminhos terminam na mesma notificação, no mesmo
handler e no mesmo toque. O `expo-notifications` continua funcionando para os lembretes locais de qualquer
jeito, então os lembretes do planner não mudariam.
