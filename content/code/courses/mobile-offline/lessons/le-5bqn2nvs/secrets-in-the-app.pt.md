---
title: Um segredo no app é um segredo que você publicou
version: 1
---

**Qualquer coisa compilada dentro de um app pode ser lida por quem o baixa, então um app não
consegue guardar um segredo dos próprios usuários.** A imagem tentadora é a de que uma chave dentro
de um app compilado fica escondida: está num binário, minificada, talvez codificada, e ninguém iria
procurar. As pessoas procuram, com ferramentas que desmontam um pacote Android ou um app iOS em um
minuto, e procuram exatamente as sequências de que uma chave é feita. Uma chave que vai no app deve
ser tratada como publicada no dia em que o app chega à loja.

Esta aula fecha o curso com o que **não** deve estar no aparelho, e isso vem primeiro porque é o
caso que nenhuma criptografia da aula 19 salva: o app precisa usar a chave, então o app precisa
conseguir lê-la, e quem tem o app também consegue.

## Um build, em miniatura

O planner quer dicas de estudo de um serviço de terceiros que cobra por requisição e deu uma chave
à equipe. A primeira versão põe a chave na configuração, ao lado do endereço do serviço. Salve estes
três arquivos na `~/planner/secrets`. Primeiro o `config.json`:

```json
{
  "server": "https://tips.example.com",
  "tipsApiKey": "tips_live_4f9c2a7e1b6d83a0"
}
```

Depois o código da tela, `app.ts`, que só usa o endereço:

```typescript
// app.ts: the planner's screen asks for a study tip for a course.
async function tip(course) {
  const res = await fetch(`${CONFIG.server}/tip?course=${course}`);
  return res.text();
}
```

E o `bundle.ts`, que faz com eles o que um build faz: um arquivo só, a configuração embutida, os
comentários e a indentação removidos:

```typescript
// bundle.ts: what a build does to the planner, in miniature: the configuration and the code
// become one file that ships inside the app, with the comments and the indentation removed.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";

const config = JSON.parse(readFileSync("config.json", "utf8"));
const code = readFileSync("app.ts", "utf8")
  .split("\n")
  .filter((line) => !line.trim().startsWith("//"))
  .map((line) => line.trim())
  .join("");
mkdirSync("dist", { recursive: true });
writeFileSync("dist/app.js", `const CONFIG=${JSON.stringify(config)};${code}\n`);
console.log(`dist/app.js: ${readFileSync("dist/app.js").length} bytes`);
```

Faça o build e procure o formato da chave no que iria para a loja:

```
ana@dev:~/planner/secrets$ node bundle.ts
dist/app.js: 206 bytes
ana@dev:~/planner/secrets$ grep -o 'tips_live_[0-9a-f]*' dist/app.js
tips_live_4f9c2a7e1b6d83a0
```

**O código nunca usou `tipsApiKey`, e ela foi junto mesmo assim.** Um empacotador embute a
configuração que recebe, então uma chave em qualquer lugar do que o build lê está no pacote. O mesmo
vale para os campos do `BuildConfig` e as strings de recurso do Android, o `Info.plist` de um app iOS e as variáveis de ambiente que o Expo embute no build com nomes começando por `EXPO_PUBLIC_`. A documentação do Expo diz com todas as letras que essas ficam visíveis no app. Codificar a chave em
base64 ou parti-la em duas muda o comando que alguém digita para achá-la, e mais nada.

## A correção é um servidor que guarda a chave

A chave vai para o servidor do próprio planner, com quem o app já precisa falar para sincronizar, e
o app pede a dica a esse servidor. O servidor acrescenta a chave do lado dele, onde ninguém a baixa.
A configuração perde uma linha. Salve o segundo `config.json`:

```json
{
  "server": "http://127.0.0.1:8020"
}
```

```
ana@dev:~/planner/secrets$ node bundle.ts
dist/app.js: 161 bytes
ana@dev:~/planner/secrets$ grep -c 'tips_live_' dist/app.js
0
```

Mover a chave rende mais do que escondê-la. O servidor agora pode recusar quem não entrou na conta, contar
requisições por conta e trocar a chave sem uma nova versão na loja. A próxima seção o escreve, com
os tokens que dizem a ele quem está pedindo.
