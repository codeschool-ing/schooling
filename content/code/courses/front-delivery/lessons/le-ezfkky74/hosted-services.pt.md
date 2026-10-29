---
title: Serviços hospedados
version: 1
---

**Um serviço hospedado é a mesma cadeia, mantida por outra pessoa: um SDK na página no lugar do
`monitor.ts`, um coletor que agrupa, alerta e guarda histórico, e um lugar para mandar os source maps.** O
**Sentry** é o mais usado, e também é de código aberto e pode rodar nos seus próprios servidores. O
**Bugsnag**, o **Rollbar**, o **Honeybadger** e o **GlitchTip**, um serviço de código aberto menor
compatível com o SDK do Sentry, fazem o mesmo trabalho. O Datadog e o New Relic o incluem em produtos de
monitoramento maiores.

**Nada nesta seção foi executado para este curso**: cada serviço exige uma conta, e os planos e telas de
cada um mudam no próprio ritmo. O que segue é a forma que a documentação do Sentry dava em outubro de 2026
para um app de navegador simples construído com Vite.

## O SDK

```typescript
// src/monitor.ts, with Sentry instead of the planner's own report
import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  release: import.meta.env.VITE_RELEASE,
  sendDefaultPii: false,
  beforeSend(event) {
    if (event.request?.url) event.request.url = event.request.url.split("?")[0];
    return event;
  },
});

export function report(error: unknown, source: string): void {
  Sentry.captureException(error, { tags: { source } });
}
```

- **O DSN** é o endereço para onde o SDK manda. Ele não é segredo: está em toda cópia da página, e
  qualquer pessoa pode mandar relatórios para ele, e é por isso que os serviços limitam a taxa e filtram do
  lado deles.
- **`release`** é a release desta aula, e precisa ser igual ao nome sob o qual os source maps são
  enviados.
- **`sendDefaultPii: false`** impede o SDK de anexar por conta própria endereços IP, cookies e cabeçalhos
  de requisição. É o padrão, e escrevê-lo diz que alguém decidiu.
- **`beforeSend`** vê cada evento antes de ele sair da página e pode mudá-lo ou descartá-lo. Aqui ele tira
  a query string do endereço, a mesma regra do `pathname` do planner.
- O SDK instala os próprios listeners de `error` e `unhandledrejection`, então o `watchErrors` não é
  necessário.

## Os maps

O plugin do Sentry para o Vite manda os maps no fim de cada build e os apaga de `dist/`, para que não
possam ir para o ar por engano:

```typescript
// vite.config.ts, with the upload added
import { sentryVitePlugin } from "@sentry/vite-plugin";

export default defineConfig({
  build: { sourcemap: "hidden" },
  plugins: [
    sentryVitePlugin({
      org: "the-team",
      project: "planner",
      authToken: process.env.SENTRY_AUTH_TOKEN,
      sourcemaps: { filesToDeleteAfterUpload: ["./dist/**/*.map"] },
    }),
  ],
});
```

**O token de autenticação é segredo**, ao contrário do DSN: ele pode enviar, e em alguns planos apagar, os
dados de um projeto. Ele vai onde a aula 2 pôs os segredos, nas configurações do pipeline, e nunca num
arquivo do repositório nem numa variável `VITE_`, que o poria em toda cópia da página.

## Escolhendo

As mesmas perguntas que a aula 1 faz a um host, e mais uma. Onde os relatórios ficam guardados, e dá para
escolher a região? O serviço pode rodar nos seus próprios servidores, se os relatórios não puderem sair
deles? O que ele remove sozinho, e o que precisa que lhe digam? E para uma equipe no Brasil: ele oferece os
termos que a LGPD exige para uma transferência internacional?
