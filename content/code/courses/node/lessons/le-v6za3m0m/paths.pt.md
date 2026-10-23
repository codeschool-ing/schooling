---
title: Caminhos, e manter um usuário dentro de uma pasta
version: 1
---

**Um caminho montado colando strings quebra na primeira entrada que ninguém esperava.** O `node:path`
junta, divide e arruma caminhos com as regras do sistema operacional, e é o único jeito de um servidor
montar um:

```javascript
// paths.js
import path from "node:path";

console.log(path.join("/home/ana/server", "files", "data", "links.json"));
console.log(path.join("/srv/uploads", "../../etc/passwd"));
console.log(path.basename("/srv/uploads/report.pdf"), path.extname("report.tar.gz"));
console.log(path.resolve("data/links.json"));
console.log(path.join(import.meta.dirname, "data"));
```

```
ana@dev:~/server/files$ node paths.js
/home/ana/server/files/data/links.json
/etc/passwd
report.pdf .gz
/home/ana/server/files/data/links.json
/home/ana/server/files/data
```

- **O `join` normaliza**, então o `..` é aplicado e não mantido, que é exatamente o que torna perigosa
  a segunda linha: um nome de arquivo que um cliente mandou, `../../etc/passwd`, juntado a uma pasta de
  uploads, aponta para fora dela.
- **O `resolve` torna um caminho absoluto** a partir da pasta onde você está, o `process.cwd()`, e o
  **`import.meta.dirname`** a partir da pasta onde o programa está. A aula 3 explicou por que o segundo
  é o que serve de base.

## Ficando dentro

Um servidor que lê ou escreve um arquivo cujo nome veio de um cliente — um upload, um download, um
template — tem uma regra. **Resolva o caminho final, e confira se ele continua dentro da pasta.** Não
procurando `..` na entrada, o que deixa passar as formas em que ninguém pensou, e sim comparando onde
o caminho termina:

```javascript
// inside.js
import path from "node:path";

function inside(root, name) {
  const base = path.resolve(root);
  const target = path.resolve(base, name);
  if (target !== base && !target.startsWith(base + path.sep)) throw new Error(`${name} is outside ${base}`);
  return target;
}

for (const name of ["report.pdf", "2026/october.csv", "../secrets.txt", "/etc/passwd", "a/../../b"]) {
  try {
    console.log(`ok       ${inside("/srv/uploads", name)}`);
  } catch (err) {
    console.log(`refused  ${err.message}`);
  }
}
```

```
ana@dev:~/server/files$ node inside.js
ok       /srv/uploads/report.pdf
ok       /srv/uploads/2026/october.csv
refused  ../secrets.txt is outside /srv/uploads
refused  /etc/passwd is outside /srv/uploads
refused  a/../../b is outside /srv/uploads
```

**O `+ path.sep` importa**: sem ele, `/srv/uploads-old/x` começa com `/srv/uploads` e passaria. Um
nome absoluto como `/etc/passwd` também é pego, porque o `resolve` deixa que ele substitua a base
inteira, e a comparação vê onde ele caiu. O `express.static` do Express, na aula 6, fazia essa
conferência por você; qualquer rota sua que mexa no sistema de arquivos precisa fazê-la sozinha.
