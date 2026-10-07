---
title: Uma cifragem que percebe a alteração
version: 1
---

**Cifrar dados os esconde; não os protege de serem alterados.** O CBC e o CTR decifram qualquer
sequência de bytes que recebem, inclusive uma que alguém alterou no caminho ou no disco, e devolvem
o resultado sem dizer uma palavra. Os modos que recusam se chamam **cifragem autenticada**, e o GCM
é o que esta seção usa.

## O que os modos simples não conseguem dizer

A seção 04 já mostrou o sintoma pelo outro lado: uma cifra transforma qualquer entrada em alguma
saída, e o `bad decrypt` que você viu era o preenchimento não se encaixando, não a cifra detectando
alguma coisa. No CTR, que não tem preenchimento, não há nem isso. Um byte alterado num texto cifrado
CTR altera o mesmo byte do texto claro e nada mais, e a decifragem dá certo. No CBC, uma alteração
embaralha um bloco e modifica o seguinte, e a decifragem em geral também dá certo.

Então um programa que decifra com um modo simples e depois confia no que leu está confiando que o
armazenamento e a rede não mudaram nada. **Confidencialidade e integridade são duas propriedades, e
os modos simples dão só a primeira.** Antes de os modos autenticados serem comuns, a solução era
acrescentar uma verificação separada sobre o texto cifrado, um MAC, que a aula 6 constrói. Errar a
ordem das duas foi uma fonte duradoura de falhas, e é por isso que os modos combinados venceram.

## GCM: um modo com etiqueta

O GCM, *Galois/Counter Mode*, é o CTR para a cifragem mais uma **etiqueta** (*tag*), dezesseis
bytes calculados sobre o texto cifrado inteiro com a mesma chave. A decifragem recalcula a etiqueta
primeiro e se recusa a devolver qualquer coisa se ela for diferente. A biblioteca `cryptography`
do Python o oferece como `AESGCM`, e duas ferramentas curtas o levam para a linha de comando. O
`vcrypt seal` cifra um arquivo e grava o nonce na frente do resultado, para que o arquivo carregue o
que a decifragem precisa:

```py
# ~/lab/tools/seal.py
"""vcrypt seal --key KEYFILE --nonce HEX [--aad TEXT] IN OUT: encrypt IN with
AES-256-GCM and write OUT as nonce + ciphertext + tag. IN may be -."""
import argparse
import sys

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

p = argparse.ArgumentParser(prog="vcrypt seal")
p.add_argument("--key", required=True, help="a file holding the key in hex")
p.add_argument("--nonce", required=True, help="12 bytes in hex, never used twice with one key")
p.add_argument("--aad", help="associated data: checked by the tag, not encrypted, not stored")
p.add_argument("infile")
p.add_argument("outfile")
a = p.parse_args()

key = bytes.fromhex(open(a.key).read().strip())
nonce = bytes.fromhex(a.nonce)
data = sys.stdin.buffer.read() if a.infile == "-" else open(a.infile, "rb").read()
out = AESGCM(key).encrypt(nonce, data, a.aad.encode() if a.aad else None)
with open(a.outfile, "wb") as f:
    f.write(nonce + out)
print(f"sealed {a.infile}: 12-byte nonce + {len(out) - 16} bytes of ciphertext + 16-byte tag -> {a.outfile}")
```

O `vcrypt open` lê o nonce de volta e recebe ou o texto claro ou uma exceção, nunca os dois:

```py
# ~/lab/tools/open.py
"""vcrypt open --key KEYFILE [--aad TEXT] IN: check the tag of a file seal
wrote and, only if it holds, print the plaintext."""
import argparse
import sys

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

p = argparse.ArgumentParser(prog="vcrypt open")
p.add_argument("--key", required=True)
p.add_argument("--aad")
p.add_argument("infile")
a = p.parse_args()

key = bytes.fromhex(open(a.key).read().strip())
blob = sys.stdin.buffer.read() if a.infile == "-" else open(a.infile, "rb").read()
try:
    plain = AESGCM(key).decrypt(blob[:12], blob[12:], a.aad.encode() if a.aad else None)
except InvalidTag:
    print(f"{a.infile}: authentication failed, nothing decrypted", file=sys.stderr)
    sys.exit(1)
sys.stdout.buffer.write(plain)
```

O `AESGCM` confere a etiqueta dentro de `decrypt`, antes de devolver um único byte. Aqui estão as
duas no arquivo de agendamentos, com AES-256-GCM:

```
ana@lab:~/lab$ vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000001 data/slots.dat slots.gcm
sealed data/slots.dat: 12-byte nonce + 512 bytes of ciphertext + 16-byte tag -> slots.gcm
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex slots.gcm | head -3
room1 free     
room1 BOOKED   
room1 free     
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"O arquivo que o vcrypt seal grava: um nonce de 12 bytes, depois 512 bytes de texto cifrado, depois uma etiqueta de 16 bytes. Uma chave mostra que a etiqueta é calculada sobre o nonce, o texto cifrado e os dados associados, que são verificados mas não ficam gravados no arquivo.\"><rect x=\"20\" y=\"60\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nonce</text><text x=\"65\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><rect x=\"110\" y=\"60\" width=\"470\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">texto cifrado (AES em modo contador)</text><text x=\"345\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">512</text><rect x=\"580\" y=\"60\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">etiqueta</text><text x=\"615\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><polyline points=\"20,120 20,130 580,130 580,120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">coberto pela etiqueta, junto com os dados associados (--aad)</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Um bit alterado em qualquer ponto daqui, e o open recusa o arquivo inteiro.</text></svg>", "caption": "slots.gcm, byte a byte: a etiqueta no fim responde por tudo o que vem antes.", "same": ["nonce"]}
```

Agora um bit do texto cifrado é alterado, o tipo de alteração que um disco com defeito ou uma rede
hostil poderia fazer. Uma terceira ferramenta faz isso:

```py
# ~/lab/tools/flip.py
"""vcrypt flip FILE OFFSET: change one bit of one byte of FILE, in place."""
import sys

path, offset = sys.argv[1], int(sys.argv[2])
data = bytearray(open(path, "rb").read())
data[offset] ^= 0x01
open(path, "wb").write(data)
print(f"{path}: byte {offset} XOR 0x01")
```

E o arquivo é aberto de novo com a chave certa:

```
ana@lab:~/lab$ vcrypt flip slots.gcm 18
slots.gcm: byte 18 XOR 0x01
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex slots.gcm | head -3; echo "exit status ${PIPESTATUS[0]}"
slots.gcm: authentication failed, nothing decrypted
exit status 1
```

**Nada é devolvido.** Nem um bloco embaralhado, nem os primeiros horários e um erro depois: a
etiqueta não bateu, então o arquivo inteiro é recusado e o código de saída diz isso. O byte 18 está
no texto cifrado, mas uma alteração no nonce ou na própria etiqueta falha do mesmo jeito, porque a
etiqueta cobre tudo o que a decifragem usa.

Essa recusa é o comportamento sobre o qual construir. Um código que recebe uma falha de
autenticação trata os dados como ausentes: não tenta outra chave até algo decifrar, não mostra a
parte que voltou e registra a falha como um evento que merece atenção.

## Dados verificados, mas não cifrados

O GCM também pode cobrir bytes que ele não cifra, chamados **dados autenticados adicionais**
(*additional authenticated data*). O identificador de um registro, o id do paciente a que ele
pertence, a versão do formato: tudo isso precisa continuar legível para o sistema achar e
encaminhar o registro, mas ninguém deveria conseguir mover um texto cifrado da linha de um paciente
para a de outro. Passar o id do paciente como dado associado amarra os dois. O texto cifrado copiado
para outra linha não abre, porque a etiqueta foi calculada com o id original:

```
ana@lab:~/lab$ vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000002 --aad patient=4471 data/referral.txt referral.gcm
sealed data/referral.txt: 12-byte nonce + 170 bytes of ciphertext + 16-byte tag -> referral.gcm
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex --aad patient=4471 referral.gcm | head -1
Referral 2026-0417. Patient: Marina Duarte, 41.
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex --aad patient=5120 referral.gcm; echo "exit status $?"
referral.gcm: authentication failed, nothing decrypted
exit status 1
```

## O que o GCM pede em troca

A única exigência do GCM é a regra do nonce da seção anterior, e aqui ela é mais rígida do que no
CTR. Um nonce repetido sob a mesma chave expõe o fluxo de chave, como no CTR, e também enfraquece a
etiqueta, de modo que a verificação em que esta seção se apoia deixa de ser confiável para aquela
chave. Onde não dá para garantir que um nonce seja único, por exemplo em muitas máquinas cifrando
com uma mesma chave e sem contador compartilhado, o **AES-GCM-SIV** foi projetado para falhar com
suavidade: um nonce repetido revela apenas que duas mensagens eram idênticas. A aula 17 volta ao
reuso de nonce como um dos três erros clássicos.

O resumo da aula cabe numa linha: **AES com chave de 128 ou 256 bits, em GCM, com um nonce que
nunca se repete, e toda falha ao abrir tratada como um ataque.**
