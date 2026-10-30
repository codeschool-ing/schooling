---
title: Recarregamento ao vivo num celular, e por que ele nunca é entregue
version: 1
---

**Construir e sincronizar leva segundos, e o build nativo depois disso leva mais.** Para uma mudança
no texto de um botão, é uma volta longa. Em vez disso, o Capacitor pode apontar a WebView para o seu
servidor de desenvolvimento, e o app no celular recarrega como o `npm run dev` faz no seu navegador. É
uma configuração no `capacitor.config.ts`:

```typescript
const config: CapacitorConfig = {
  appId: "com.example.studyplanner",
  appName: "Study planner",
  webDir: "dist",
  server: {
    url: "http://192.0.2.20:5173", // your computer's address on the network
    cleartext: true,
  },
};
```

Três condições fazem isso funcionar. **O celular e o computador estão na mesma rede**, e o endereço é
o do computador nela, não `localhost`, que no celular quer dizer o celular. **O servidor de
desenvolvimento escuta nessa rede**, o que `npm run dev -- --host` faz; por padrão o Vite escuta só no
próprio computador, e o banner de início dele diz isso com `use --host to expose`. E **o Android
permite `http` simples** para esse endereço, que é o que `cleartext: true` pede.

A CLI do Capacitor faz o mesmo sem editar o arquivo: `npx cap run android --live-reload --host
192.0.2.20 --port 5173` escreve a configuração só para aquela execução. *Nenhuma das duas formas foi
rodada para este curso, porque elas precisam de um celular ou de um emulador; a aula 3 diz por que não
havia nenhum.*

## Por que ele nunca é entregue

**Um app com `server.url` configurado não contém o seu app.** Ele contém uma WebView que abre um
endereço da sua rede, e no celular de qualquer outra pessoa esse endereço é nada, ou o computador de
outra pessoa. Com `cleartext`, ele busca o código sem criptografia, então qualquer um na mesma rede
consegue ler ou mudar o que o app roda. Os revisores das duas lojas veem um app que é uma página remota.

Por isso a regra é mecânica: **o `server.url` é apagado, ou nunca entra num commit, antes de um build
de lançamento**. A forma `--live-reload` do `cap run` existe exatamente por isso: a configuração vive
por uma execução, e o arquivo no git nunca a tem. A lista de conferência de lançamento da aula 13 tem
uma linha que procura por ela.
