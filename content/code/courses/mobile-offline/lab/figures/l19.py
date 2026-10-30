"""Lesson 19: envelope encryption, and the program that does it."""
from fig import Fig

T = {
    "en": dict(
        aria="Envelope encryption. Inside the phone's hardware, the Keystore or Keychain, sits the key-encryption key, which never leaves it. On the disk sit the wrapped data key, dek.wrapped, and the sealed data, sessions.enc. To read, the hardware unwraps the data key, the data key opens the sessions, and the data key is then let go.",
        hw="the hardware: Keystore or Keychain", kek="key-encryption key", never="never leaves",
        disk="the disk, in the sandbox", dek="the data key, wrapped", data="the sessions, sealed",
        unwrap="unwraps", opens="opens",
        cap="Two keys. The one stored beside the data is useless without the one that never leaves the hardware.",
    ),
    "pt": dict(
        aria="Criptografia de envelope. Dentro do hardware do celular, o Keystore ou o Keychain, fica a chave de cifrar chaves, que nunca sai dali. No disco ficam a chave de dados embrulhada, dek.wrapped, e o dado selado, sessions.enc. Para ler, o hardware desembrulha a chave de dados, a chave de dados abre as sessões, e depois a chave de dados é descartada.",
        hw="o hardware: Keystore ou Keychain", kek="chave de cifrar chaves", never="nunca sai",
        disk="o disco, na caixa de areia", dek="a chave de dados, embrulhada", data="as sessões, seladas",
        unwrap="desembrulha", opens="abre",
        cap="Duas chaves. A que fica guardada ao lado do dado não serve para nada sem a que nunca sai do hardware.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l19-envelope", 720, 250, t["aria"])
    f.rect(20, 20, 220, 210, stroke="phosphor", fill="panel", dashed=True)
    f.text(130, 42, t["hw"], size=9.5, fill="phosphor", bold=True)
    f.box(40, 100, 180, 50, [t["kek"]], stroke="phosphor", ground="ink")
    f.text(130, 170, t["never"], size=9.5, fill="paper-dim", italic=True)
    f.rect(300, 20, 400, 210, stroke="wire", fill="panel")
    f.text(500, 42, t["disk"], size=9.5, fill="paper-dim", bold=True)
    f.box(330, 70, 170, 50, [t["dek"], "dek.wrapped"], stroke="amber", ground="ink")
    f.box(510, 150, 170, 50, [t["data"], "sessions.enc"], stroke="wire", ground="ink")
    f.arrow([(220, 125), (328, 95)], color="phosphor")
    f.text(274, 96, t["unwrap"], size=9, fill="phosphor")
    f.arrow([(500, 110), (560, 148)], color="amber")
    f.text(538, 118, t["opens"], size=9, fill="amber", anchor="start")
    return {"l19-envelope": f.json(t["cap"], same=None if lang == "en" else ["dek.wrapped", "sessions.enc"])}


EXAMPLES = {"encrypting-the-data": [
    {"language": "typescript", "file": "crypt.ts", "parts": [
 [
  "// crypt.ts: the planner's sessions encrypted at rest, with a data key wrapped by a key-encryption key.\n// usage: node crypt.ts init | node crypt.ts seal | node crypt.ts open\nimport { randomBytes, createCipheriv, createDecipheriv } from \"node:crypto\";\nimport { readFileSync, writeFileSync, existsSync } from \"node:fs\";\nimport { sessions } from \"../data.ts\";\n",
  "The program has three commands, and imports the six sessions of lesson 1 to have something to protect.",
  "O programa tem três comandos, e importa as seis sessões da aula 1 para ter o que proteger."
 ],
 [
  "// AES-256-GCM: a 12-byte nonce that is never used twice with one key, and a 16-byte tag\n// that fails the decryption if a single bit of the file changed.\nfunction seal(key: Buffer, plain: Buffer): Buffer {\n  const nonce = randomBytes(12);\n  const c = createCipheriv(\"aes-256-gcm\", key, nonce);\n  const body = Buffer.concat([c.update(plain), c.final()]);\n  return Buffer.concat([nonce, c.getAuthTag(), body]);\n}",
  "Sealing draws a fresh 12-byte nonce every time and writes it in front of the tag and the ciphertext, so the file carries everything opening needs except the key.",
  "Selar sorteia um nonce novo de 12 bytes toda vez e o grava na frente da etiqueta e do texto cifrado, então o arquivo leva tudo o que abrir precisa, menos a chave."
 ],
 [
  "function open(key: Buffer, sealed: Buffer): Buffer {\n  const d = createDecipheriv(\"aes-256-gcm\", key, sealed.subarray(0, 12));\n  d.setAuthTag(sealed.subarray(12, 28));\n  return Buffer.concat([d.update(sealed.subarray(28)), d.final()]);\n}\n",
  "Opening reads the three pieces back. `final()` throws if the tag does not match, which is the refusal the tampered run shows.",
  "Abrir lê as três partes de volta. O `final()` lança um erro se a etiqueta não bate, que é a recusa que a execução adulterada mostra."
 ],
 [
  "// kek.bin stands in for the key a phone keeps in its Keystore or Keychain, which never leaves\n// the hardware. Only the data key, wrapped by it, is stored beside the data.\nconst kek = () => readFileSync(\"kek.bin\");\nconst dataKey = () => open(kek(), readFileSync(\"dek.wrapped\"));\n",
  "The two keys. On a phone `kek()` is a call to the Keystore or the Keychain, and the data key exists only for as long as one seal or one open takes.",
  "As duas chaves. Num celular, `kek()` é uma chamada ao Keystore ou ao Keychain, e a chave de dados só existe durante um selamento ou uma abertura."
 ],
 [
  "const cmd = process.argv[2];\nif (cmd === \"init\") {\n  writeFileSync(\"kek.bin\", randomBytes(32));\n  writeFileSync(\"dek.wrapped\", seal(kek(), randomBytes(32)));\n  console.log(\"made a key-encryption key and a wrapped data key\");",
  "`init` makes both keys once. The data key is written to the disk already wrapped; its plain form is never saved.",
  "O `init` cria as duas chaves uma vez. A chave de dados vai para o disco já embrulhada; a forma aberta dela nunca é salva."
 ],
 [
  "} else if (cmd === \"seal\") {\n  const before = existsSync(\"sessions.enc\") ? readFileSync(\"sessions.enc\") : undefined;\n  const out = seal(dataKey(), Buffer.from(JSON.stringify(sessions)));\n  writeFileSync(\"sessions.enc\", out);\n  console.log(`sealed ${sessions.length} sessions into ${out.length} bytes` +\n    (before ? `; same bytes as the last seal: ${before.equals(out) ? \"yes\" : \"no\"}` : \"\"));",
  "`seal` encrypts the sessions and compares the result with the last seal, to show that the same data never gives the same bytes.",
  "O `seal` cifra as sessões e compara o resultado com o selamento anterior, para mostrar que o mesmo dado nunca dá os mesmos bytes."
 ],
 [
  "} else if (cmd === \"open\") {\n  try {\n    const list = JSON.parse(open(dataKey(), readFileSync(\"sessions.enc\")).toString()) as typeof sessions;\n    console.log(`opened ${list.length} sessions; the first is ${list[0].id}, ${list[0].course}, ${list[0].date}`);\n  } catch (e) {\n    console.log(`refused: ${(e as Error).message}`);\n    process.exitCode = 1;\n  }\n}",
  "`open` decrypts, or says why it refused. A refusal sets a failing exit code rather than printing nothing.",
  "O `open` decifra, ou diz por que recusou. Uma recusa marca um código de saída de falha em vez de não imprimir nada."
 ]
]},
]}
