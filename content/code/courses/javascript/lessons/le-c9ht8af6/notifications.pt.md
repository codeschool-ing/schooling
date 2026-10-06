---
title: Notificações e a Permissions API
version: 1
---

Uma notificação é uma mensagem que o sistema operacional mostra **fora da página**, mesmo quando a aba
dela está em segundo plano: um livro reservado está pronto para retirar. Como ela alcança fora da
página, precisa da permissão do usuário, e a **Permissions API** deixa uma página perguntar o que já foi
decidido sem perguntar nada ao usuário:

```html
<!doctype html>
<script>
  for (const name of ["geolocation", "notifications"]) {
    navigator.permissions.query({ name }).then((status) => console.log(name, status.state));
  }
</script>
```

```
ana@dev:~/js$ page permissions.html --fresh
geolocation prompt
notifications prompt
ana@dev:~/js$ page permissions.html --fresh --geo -23.5503,-46.6339 --grant notifications
geolocation granted
notifications granted
```

Cada permissão fica num de três estados:

- **`prompt`**: ninguém decidiu. Pedir vai mostrar a pergunta do navegador. É onde um perfil novo
  começa, como mostra a primeira execução;
- **`granted`**: permitida, como na segunda execução, em que o `page` concedeu as duas;
- **`denied`**: recusada. **A página não pode pedir de novo**; só o usuário pode mudar isso, nas
  configurações do site no navegador.

## Mostrando uma

Mostrar uma notificação são dois passos: `await Notification.requestPermission()`, que mostra a
pergunta se o estado for `prompt` e devolve a resposta, e depois `new Notification("Iracema is ready
to collect", { body: "Shelf A, until Friday" })`. **Isso não foi capturado**: o navegador do
laboratório roda sem tela e não consegue exibir uma notificação, então uma transcrição mostraria só a
falha dele, que não é o que um navegador de verdade faz.

As regras são as que a geolocalização ensinou, pelo mesmo motivo:

- **peça em resposta a algo que o usuário fez**, como ligar "me avise quando estiver pronto". Os
  navegadores ignoram ou bloqueiam em silêncio um pedido feito ao carregar a página;
- **use `navigator.permissions.query` para decidir o que mostrar**: um botão "ativar notificações"
  quando o estado é `prompt`, uma nota sobre as configurações do navegador quando é `denied`, nada
  quando é `granted`;
- uma notificação que chega com a página fechada precisa de um **service worker** e de um serviço de
  push, que pertencem aos capítulos de offline dos próximos cursos, e não a este.
