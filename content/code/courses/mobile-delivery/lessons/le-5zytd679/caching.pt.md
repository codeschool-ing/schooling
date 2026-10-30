---
title: Cache, e a chave que o decide
version: 1
---

**Um build mobile baixa muita coisa antes de compilar qualquer coisa**: as dependências do Gradle e
a própria distribuição dele, os pacotes npm de um projeto React Native, CocoaPods ou Swift packages
para o iOS. Num runner novo, toda execução baixa tudo de novo. Um cache guarda essas pastas no fim
de uma execução e as restaura no começo da seguinte, e **todo o desenho de um cache é a chave** sob a
qual ele é guardado.

## O que uma chave precisa fazer

- **Mudar quando o que foi baixado mudaria.** Isso acontece quando um lockfile muda:
  `package-lock.json`, `gradle/libs.versions.toml` e as propriedades do wrapper, `Podfile.lock`,
  `Package.resolved`.
- **Não mudar por mais nada.** Editar um arquivo de código não pode jogar fora um cache de
  dependências perfeitamente bom.
- **Dizer para qual sistema ele é**: um cache de módulos nativos compilados no Linux restaurado num
  Mac é pior do que nenhum.

Então a chave de costume é o sistema operacional mais um hash dos lockfiles. O GitHub Actions a
escreve como `${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}`, e o próximo script
calcula o mesmo tipo de chave, no seu computador, para mostrar quando ela muda.

## Uma chave de cache, calculada

Salve isto como `cachekey.ts` em `~/planner`:

```typescript
// cachekey.ts: the cache key a pipeline would use, from the operating system and the lockfiles
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { platform } from "node:os";

const files = process.argv.slice(2);
const hash = createHash("sha256");
for (const f of files.sort()) hash.update(readFileSync(f));
console.log(`${platform()}-deps-${hash.digest("hex").slice(0, 12)}`);
```

Depois peça a chave, mude um arquivo de código, peça de novo, acrescente uma dependência, peça de
novo, e tire a dependência:

```
ana@dev:~/planner$ node cachekey.ts package-lock.json
linux-deps-9ce97dd3ef27
ana@dev:~/planner$ echo "// a source change" >> check.ts && node cachekey.ts package-lock.json
linux-deps-9ce97dd3ef27
ana@dev:~/planner$ npm install -E dayjs@1.11.13 --silent && node cachekey.ts package-lock.json
linux-deps-00ced0936e82
ana@dev:~/planner$ npm uninstall dayjs --silent && node cachekey.ts package-lock.json
linux-deps-9ce97dd3ef27
```

**A chave só se moveu quando o lockfile se moveu**, e voltou ao primeiro valor quando o lockfile
voltou. Essa última linha é a propriedade que torna um cache confiável: a chave é função do conteúdo
do lockfile, e não do tempo nem de qual execução o produziu.

## O que não pôr em cache

- **Saídas de build entre commits sem relação.** O build cache do Gradle pode ser compartilhado com
  segurança porque identifica cada tarefa pelas entradas dela; uma pasta de classes compiladas
  guardada à mão não pode.
- **Qualquer coisa que guarde um segredo.** Um cache é legível por execuções seguintes, inclusive de
  pull requests em algumas configurações; um keystore restaurado de um cache é um keystore publicado.
- **O artefato assinado.** Ele é enviado como artefato de build ou direto para a loja, onde o tempo
  de guarda é decidido de propósito.
