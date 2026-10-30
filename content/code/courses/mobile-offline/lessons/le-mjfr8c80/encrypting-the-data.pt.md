---
title: Cifrar o dado com uma chave que o app nunca segura
version: 1
---

**A criptografia do próprio app usa duas chaves, e a que importa nunca sai do hardware.** Uma chave
só, guardada ao lado do dado que protege, é um cadeado com a chave colada nele, e é o desenho que as
pessoas pegam primeiro: gerar uma chave, salvar num arquivo, cifrar o banco com ela. Um backup que
copia o banco copia a chave junto.

O desenho que funciona se chama **criptografia de envelope**:

- uma **chave de dados**, aleatória, cifra o dado do planner. Ela fica no disco, mas só
  **embrulhada**: cifrada ela mesma.
- uma **chave de cifrar chaves** embrulha a chave de dados. Ela mora no Android Keystore ou no
  Keychain do iOS, que a seção anterior mostrou, e nunca sai dali.

Para ler, o app pede ao hardware para desembrulhar a chave de dados, decifra e descarta a chave de
dados. A divisão tem um segundo uso: trocar a chave de cifrar chaves, depois de uma mudança na
biometria por exemplo, significa embrulhar de novo 32 bytes em vez de cifrar de novo o banco
inteiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l19-envelope\" aria-label=\"Criptografia de envelope. Dentro do hardware do celular, o Keystore ou o Keychain, fica a chave de cifrar chaves, que nunca sai dali. No disco ficam a chave de dados embrulhada, dek.wrapped, e o dado selado, sessions.enc. Para ler, o hardware desembrulha a chave de dados, a chave de dados abre as sessões, e depois a chave de dados é descartada.\"><defs><marker id=\"l19-envelope-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-envelope-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o hardware: Keystore ou Keychain</text><rect x=\"40\" y=\"100\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de cifrar chaves</text><text x=\"130\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca sai</text><rect x=\"300\" y=\"20\" width=\"400\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o disco, na caixa de areia</text><rect x=\"330\" y=\"70\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a chave de dados, embrulhada</text><text x=\"415.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dek.wrapped</text><rect x=\"510\" y=\"150\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as sessões, seladas</text><text x=\"595.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sessions.enc</text><path d=\"M220 125 L328 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-envelope-ah-phosphor)\"></path><text x=\"274\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">desembrulha</text><path d=\"M500 110 L560 148\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-envelope-ah-amber)\"></path><text x=\"538\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">abre</text></svg>", "caption": "Duas chaves. A que fica guardada ao lado do dado não serve para nada sem a que nunca sai do hardware.", "same": ["dek.wrapped", "sessions.enc"]}
```

## Construído no Node, com `node:crypto`

O Node não tem Keystore, então o `kek.bin`, um arquivo, faz o papel dele aqui; essa linha é o que um
celular faz de diferente. Todo o resto é o que um app faz. Salve isto na `~/planner/crypt` como
`crypt.ts`:

```schooling-example
{"language": "typescript", "file": "crypt.ts", "parts": [{"code": "// crypt.ts: the planner's sessions encrypted at rest, with a data key wrapped by a key-encryption key.\n// usage: node crypt.ts init | node crypt.ts seal | node crypt.ts open\nimport { randomBytes, createCipheriv, createDecipheriv } from \"node:crypto\";\nimport { readFileSync, writeFileSync, existsSync } from \"node:fs\";\nimport { sessions } from \"../data.ts\";\n", "note": "O programa tem três comandos, e importa as seis sessões da aula 1 para ter o que proteger."}, {"code": "// AES-256-GCM: a 12-byte nonce that is never used twice with one key, and a 16-byte tag\n// that fails the decryption if a single bit of the file changed.\nfunction seal(key: Buffer, plain: Buffer): Buffer {\n  const nonce = randomBytes(12);\n  const c = createCipheriv(\"aes-256-gcm\", key, nonce);\n  const body = Buffer.concat([c.update(plain), c.final()]);\n  return Buffer.concat([nonce, c.getAuthTag(), body]);\n}", "note": "Selar sorteia um nonce novo de 12 bytes toda vez e o grava na frente da etiqueta e do texto cifrado, então o arquivo leva tudo o que abrir precisa, menos a chave."}, {"code": "function open(key: Buffer, sealed: Buffer): Buffer {\n  const d = createDecipheriv(\"aes-256-gcm\", key, sealed.subarray(0, 12));\n  d.setAuthTag(sealed.subarray(12, 28));\n  return Buffer.concat([d.update(sealed.subarray(28)), d.final()]);\n}\n", "note": "Abrir lê as três partes de volta. O `final()` lança um erro se a etiqueta não bate, que é a recusa que a execução adulterada mostra."}, {"code": "// kek.bin stands in for the key a phone keeps in its Keystore or Keychain, which never leaves\n// the hardware. Only the data key, wrapped by it, is stored beside the data.\nconst kek = () => readFileSync(\"kek.bin\");\nconst dataKey = () => open(kek(), readFileSync(\"dek.wrapped\"));\n", "note": "As duas chaves. Num celular, `kek()` é uma chamada ao Keystore ou ao Keychain, e a chave de dados só existe durante um selamento ou uma abertura."}, {"code": "const cmd = process.argv[2];\nif (cmd === \"init\") {\n  writeFileSync(\"kek.bin\", randomBytes(32));\n  writeFileSync(\"dek.wrapped\", seal(kek(), randomBytes(32)));\n  console.log(\"made a key-encryption key and a wrapped data key\");", "note": "O `init` cria as duas chaves uma vez. A chave de dados vai para o disco já embrulhada; a forma aberta dela nunca é salva."}, {"code": "} else if (cmd === \"seal\") {\n  const before = existsSync(\"sessions.enc\") ? readFileSync(\"sessions.enc\") : undefined;\n  const out = seal(dataKey(), Buffer.from(JSON.stringify(sessions)));\n  writeFileSync(\"sessions.enc\", out);\n  console.log(`sealed ${sessions.length} sessions into ${out.length} bytes` +\n    (before ? `; same bytes as the last seal: ${before.equals(out) ? \"yes\" : \"no\"}` : \"\"));", "note": "O `seal` cifra as sessões e compara o resultado com o selamento anterior, para mostrar que o mesmo dado nunca dá os mesmos bytes."}, {"code": "} else if (cmd === \"open\") {\n  try {\n    const list = JSON.parse(open(dataKey(), readFileSync(\"sessions.enc\")).toString()) as typeof sessions;\n    console.log(`opened ${list.length} sessions; the first is ${list[0].id}, ${list[0].course}, ${list[0].date}`);\n  } catch (e) {\n    console.log(`refused: ${(e as Error).message}`);\n    process.exitCode = 1;\n  }\n}", "note": "O `open` decifra, ou diz por que recusou. Uma recusa marca um código de saída de falha em vez de não imprimir nada."}]}
```

Crie as chaves, sele as sessões duas vezes, abra, e procure o id de um curso no arquivo selado:

```
ana@dev:~/planner/crypt$ node crypt.ts init
made a key-encryption key and a wrapped data key
ana@dev:~/planner/crypt$ node crypt.ts seal
sealed 6 sessions into 493 bytes
ana@dev:~/planner/crypt$ node crypt.ts seal
sealed 6 sessions into 493 bytes; same bytes as the last seal: no
ana@dev:~/planner/crypt$ node crypt.ts open
opened 6 sessions; the first is s1, spanish, 2026-10-19
ana@dev:~/planner/crypt$ grep -c spanish ../data.ts sessions.enc
../data.ts:3
sessions.enc:0
```

**Dois selamentos das mesmas seis sessões deram bytes diferentes**, porque cada um sorteou um nonce
novo. Essa é a regra que o GCM não sobrevive a quebrar: duas mensagens seladas com uma chave e um
nonce vazam a diferença entre elas, e deixam alguém forjar uma etiqueta. Um nonce aleatório de 12
bytes por selamento mantém a chance de repetição desprezível para qualquer número de gravações que
um celular vá fazer. E o `grep` achou `spanish` em três linhas do `data.ts` e em nenhuma do
`sessions.enc`.

Agora mude um bit do arquivo selado, sele de novo uma cópia boa, e depois tire a chave de cifrar
chaves:

```
ana@dev:~/planner/crypt$ node -e "const fs = require('fs'); const b = fs.readFileSync('sessions.enc'); b[40] ^= 1; fs.writeFileSync('sessions.enc', b)"
ana@dev:~/planner/crypt$ node crypt.ts open
refused: Unsupported state or unable to authenticate data
ana@dev:~/planner/crypt$ node crypt.ts seal
sealed 6 sessions into 493 bytes; same bytes as the last seal: no
ana@dev:~/planner/crypt$ mv kek.bin kek.away
ana@dev:~/planner/crypt$ node crypt.ts open
refused: ENOENT: no such file or directory, open 'kek.bin'
ana@dev:~/planner/crypt$ mv kek.away kek.bin
ana@dev:~/planner/crypt$ node crypt.ts open
opened 6 sessions; the first is s1, spanish, 2026-10-19
```

**Um bit, e o arquivo inteiro foi recusado.** A etiqueta do GCM cobre cada byte, então um arquivo
corrompido por um setor ruim e um arquivo alterado de propósito falham do mesmo jeito, e nenhum dos
dois é decifrado em algo plausível e errado. Sem a chave de cifrar chaves nada abre, que é o que
acontece depois de um celular ser restaurado de fábrica, e depois de um backup restaurado em outro
celular quando a chave era `ThisDeviceOnly`. **O planner precisa contar com isso**: um arquivo de
dado que ele não consegue abrir é tratado como dado nenhum, e a ressincronização completa da aula 12
traz as sessões de volta do servidor. Uma sessão que só estava no celular antigo se perdeu, que é o
argumento da caixa de saída para enviá-la logo.

## Um banco inteiro: SQLCipher

Selar um arquivo JSON é o certo para um segredo pequeno. Para o banco inteiro do planner, os apps
usam o **SQLCipher**, uma versão do SQLite que cifra cada página com AES-256, aberta com uma chave
que o app desembrulha exatamente como acima. O Android o usa por `net.zetetic:sqlcipher-android`, o
iOS pelo pacote do SQLCipher, o React Native pelo `op-sqlite` com a opção SQLCipher. *Nenhum deles
foi rodado para este curso; eles são citados da própria documentação.*
