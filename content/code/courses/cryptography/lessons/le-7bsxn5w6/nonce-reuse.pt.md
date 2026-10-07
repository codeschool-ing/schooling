---
title: Um nonce usado duas vezes
version: 1
---

**Um nonce tem uma única exigência: sob uma dada chave, ele nunca aparece duas vezes. Não precisa ser
secreto nem aleatório, só único. Quebre isso uma vez e o AES-GCM perde as duas propriedades para as
quais a aula 1 o montou.** O erro raramente é alguém digitando o mesmo número duas vezes. É um
contador que andou para trás.

## O que uma repetição custa

A aula 1 descreveu o GCM como modo contador mais uma etiqueta. O modo contador transforma a chave e o
nonce num fluxo de chave e faz XOR dele com a mensagem, então duas mensagens seladas com a mesma
chave e o mesmo nonce passaram pelo XOR com o **mesmo fluxo de chave**. Os textos cifrados delas,
combinados, cancelam o fluxo de chave e deixam os dois textos claros combinados um com o outro, e daí
em geral dá para ler boa parte dos dois, sobretudo quando os registros seguem um formato conhecido. A
etiqueta também sofre: um nonce repetido expõe o valor com que o GCM calcula as etiquetas, e depois
disso mensagens que ninguém selou conseguem passar na verificação.

Por isso a resposta nunca é "decifrar e olhar". A chave é tratada como comprometida para todo arquivo
selado com ela, e o caminho a seguir é o mesmo por menos arquivos que tenham colidido.

## Como um contador volta

A exportação da agenda da Vereda sela um arquivo por dia com `keys/aes-256.hex`, tirando o nonce de
um contador guardado num pequeno arquivo de estado. Em 8 de junho, depois de uma falha de disco, o
servidor de exportação foi restaurado do backup de 4 de junho, arquivo de estado incluído, e o
contador seguiu a partir de 5 como se os três últimos dias não tivessem acontecido. Nada falhou e nada
foi registrado. Todo arquivo abria certo depois, porque abrir um arquivo nunca confere se o nonce dele
foi usado em outro lugar.

A tarefa de exportação, como rodou nesses catorze dias, é um laço sobre o `vcrypt seal` da aula 1,
com o contador posto para trás no dia 8. Rode-o para ter os arquivos:

```sh
cd ~/lab
mkdir -p export
n=1
for d in $(seq -w 1 14); do
  [ "$d" = 08 ] && n=5   # 8 June: restored from the backup of 4 June
  printf 'agenda 2026-06-%s\nroom1 09:00 booked\nroom2 10:30 free\n' "$d" > day.txt
  vcrypt seal --key keys/aes-256.hex --nonce "$(printf '%024x' "$n")" day.txt "export/agenda-06-$d.gcm" >/dev/null
  n=$((n + 1))
done
rm day.txt
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Catorze dias da exportação da agenda, de 1 a 14 de junho, cada um selado com um nonce de um contador. Os dias 1 a 7 usam os nonces 1 a 7. Em 8 de junho o servidor é restaurado do backup de 4 de junho e o contador volta a 5, então os dias 8, 9 e 10 usam de novo os nonces 5, 6 e 7, desenhados em vermelho com linhas até os dias anteriores que os usaram. Os dias 11 a 14 usam os nonces 8 a 11.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">junho</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nonce</text><text x=\"89\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"70\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"135\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"116\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><text x=\"181\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"162\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"181\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><text x=\"227\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"208\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"227\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"273\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"254\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"273\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"319\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"300\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"319\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"365\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><rect x=\"346\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"365\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><text x=\"411\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><rect x=\"392\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"411\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><text x=\"457\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><rect x=\"438\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">6</text><text x=\"503\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><rect x=\"484\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"503\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">7</text><text x=\"549\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><rect x=\"530\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"549\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"595\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><rect x=\"576\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"641\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13</text><rect x=\"622\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"641\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"687\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><rect x=\"668\" y=\"92\" width=\"38\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"687\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11</text><polyline points=\"273,134 273,150 411,150 411,134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></polyline><polyline points=\"319,134 319,162 457,162 457,134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></polyline><polyline points=\"365,134 365,174 503,174 503,134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></polyline><polyline points=\"388,40 388,186\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><text x=\"396\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">8 de junho: restaurado do backup de 4 de junho</text></svg>", "caption": "Uma restauração, três nonces repetidos e nenhum erro em lugar nenhum. Vermelho: um nonce usado pela segunda vez.", "same": ["nonce"]}
```

## Encontrar

O nonce fica guardado às claras no começo de todo arquivo selado, então detectar uma repetição não
precisa de chave e não decifra nada. O `vcrypt nonce-audit` lê os doze primeiros bytes de cada arquivo
e informa qualquer valor que apareça mais de uma vez:

```py
# ~/lab/tools/nonce-audit.py
"""vcrypt nonce-audit FILE...: list sealed files that share a nonce. It reads
the first 12 bytes of each file, where seal wrote the nonce, and nothing
else: it needs no key and decrypts nothing. What to do about a repeat is
for whoever holds the key."""
import sys

files = sys.argv[1:]
seen = {}
for path in files:
    seen.setdefault(open(path, "rb").read(12).hex(), []).append(path)
print(f"{len(files)} sealed files, {len(seen)} different nonces")
repeated = {n: p for n, p in seen.items() if len(p) > 1}
for nonce, paths in sorted(repeated.items()):
    print(f"nonce {nonce} used {len(paths)} times: {' '.join(paths)}")
if repeated:
    print(f"{len(repeated)} nonces repeated: if these files share a key, rotate it and re-seal them")
    sys.exit(1)
print("no nonce repeated")
```

Na exportação:

```
ana@lab:~/lab$ ls export | head -3; ls export | wc -l
agenda-06-01.gcm
agenda-06-02.gcm
agenda-06-03.gcm
14
ana@lab:~/lab$ vcrypt nonce-audit export/*.gcm; echo "exit status $?"
14 sealed files, 11 different nonces
nonce 000000000000000000000005 used 2 times: export/agenda-06-05.gcm export/agenda-06-08.gcm
nonce 000000000000000000000006 used 2 times: export/agenda-06-06.gcm export/agenda-06-09.gcm
nonce 000000000000000000000007 used 2 times: export/agenda-06-07.gcm export/agenda-06-10.gcm
3 nonces repeated: if these files share a key, rotate it and re-seal them
exit status 1
```

O código de saída 1 permite que a auditoria rode como uma verificação agendada que alerta. Ela achou
os três dias que a restauração repetiu. A mesma verificação vale para qualquer depósito de registros
selados, e uma coluna de nonces no banco com um índice único faz o mesmo trabalho
continuamente, e recusa a segunda inserção no momento em que ela acontece.

## Corrigir

1. **Gere uma chave nova** e sele de novo sob ela todo arquivo da antiga, com nonces novos. A chave
   antiga então é aposentada, porque os arquivos repetidos foram selados com ela.
2. **Pare de guardar o nonce num estado que uma restauração consegue voltar.** Para poucos arquivos
   por dia, a escolha sólida mais simples é um nonce aleatório de 96 bits vindo do sistema
   operacional para cada mensagem, que é o que o `os.urandom(12)` deu ao exemplo da seção anterior.
   Nonces aleatórios de 96 bits são seguros até cerca de quatro bilhões de mensagens por chave, o
   limite que o NIST estabelece para o GCM.
3. **Onde esse limite fica perto demais**, use uma construção feita para isso: o XChaCha20-Poly1305,
   cujo nonce de 192 bits pode ser aleatório em qualquer volume realista, ou o AES-GCM-SIV, que a aula
   1 descreveu como uma construção que falha com suavidade quando um nonce se repete.

No laboratório, o primeiro passo e uma auditoria do resultado:

```
ana@lab:~/lab$ openssl rand -hex 32 > keys/agenda-2.hex
ana@lab:~/lab$ for f in export/*.gcm; do vcrypt open --key keys/aes-256.hex $f | vcrypt seal --key keys/agenda-2.hex --nonce $(openssl rand -hex 12) - ${f%.gcm}.v2 >/dev/null; done
ana@lab:~/lab$ vcrypt nonce-audit export/*.v2
14 sealed files, 14 different nonces
no nonce repeated
```

A opção `--nonce` do `vcrypt seal` existe para os arquivos do laboratório saírem iguais em toda
máquina. É um recurso didático, e uma interface que pede o nonce a quem a chama é exatamente o tipo
de interface que produz este erro. As interfaces de biblioteca que a seção 03 recomendou ou escolhem
o nonce elas mesmas, ou fazem de escolher um novo o único caminho fácil.
