---
title: Tempo limite e cancelamento
version: 2
---

**O `fetch` não tem tempo limite próprio.** Um servidor que aceita a conexão e nunca responde deixa a
promessa pendente enquanto o sistema operacional deixar a conexão viva. O jeito de desistir é um
**sinal**. Isto roda com `node`, então o servidor da seção anterior tem de estar rodando no segundo
terminal dele:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;

let t = performance.now();
try {
  await fetch("http://127.0.0.1:8080/api/slow?ms=3000", { signal: AbortSignal.timeout(1000) });
} catch (err) {
  console.log(`${err.name} after about ${round(performance.now() - t)} ms: ${err.message}`);
}

const controller = new AbortController();
t = performance.now();
setTimeout(() => controller.abort(), 300);
try {
  await fetch("http://127.0.0.1:8080/api/slow?ms=3000", { signal: controller.signal });
} catch (err) {
  console.log(`${err.name} after about ${round(performance.now() - t)} ms: ${err.message}`);
}
```

```
ana@dev:~/js$ node timeout.mjs
TimeoutError after about 1000 ms: The operation was aborted due to timeout
AbortError after about 300 ms: This operation was aborted
```

O `/api/slow` espera três segundos antes de responder. As duas requisições desistiram muito antes:

- **`AbortSignal.timeout(1000)`** é um sinal que dispara sozinho depois de 1000 ms. A requisição foi
  abandonada por volta de 1000 ms com um `TimeoutError`;
- **um `AbortController`** é um sinal que você mesmo dispara, com `controller.abort()`. Um
  temporizador o disparou aos 300 ms, e a requisição rejeitou com um `AbortError`. Numa página, a
  mesma chamada vai no handler de um botão Cancelar, ou no código que roda quando o usuário sai da
  tela que fez a requisição.

Os dois erros têm nomes diferentes de propósito, para o código distinguir **"demorou demais"** de
**"deixamos de querer"**: o primeiro vale a pena relatar ao usuário, o segundo em geral não.

Abortar para a espera deste lado. **Não desfaz o que o servidor já fez**: um `POST` que o servidor já
tinha salvado continua salvo. Esse é um dos motivos de as duas próximas seções tratarem com cuidado o
envio de dados e a tentativa de novo.

As próximas seções voltam ao `page`, que sobe um servidor próprio no mesmo endereço. **Pare antes o
do segundo terminal**, com Ctrl+C, ou o `page` para com `EADDRINUSE` (aula 1, "Quando a instalação
falha").
