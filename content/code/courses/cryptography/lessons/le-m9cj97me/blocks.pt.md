---
title: O AES trabalha em blocos de dezesseis bytes
version: 1
---

**O AES é uma cifra de bloco: recebe exatamente 16 bytes e uma chave, e devolve exatamente 16
bytes.** Não aceita 15 bytes nem 17. Qualquer que seja o tamanho da chave, 128, 192 ou 256 bits, o
bloco tem sempre 128 bits. Uma chave maior significa mais rodadas de mistura dentro da caixa (10,
12 ou 14), não um bloco maior.

Isso tem duas consequências que todo usuário de AES encontra: uma mensagem é cortada em blocos, e
o último bloco é completado até dezesseis. O resto desta aula decorre da primeira.

## Um arquivo é uma fileira de blocos

O arquivo de agendamentos da Vereda foi montado para esta aula. Cada horário da agenda de segunda
na sala 1 é um registro de largura fixa com exatamente dezesseis bytes, de modo que cada registro é
um bloco AES. O `vcrypt blocks` mostra um arquivo dezesseis bytes por vez, em hexadecimal, e marca
um bloco que já viu:

```
ana@lab:~/lab$ vcrypt blocks data/slots.dat | head -6
  1  726f6f6d31206672656520202020200a
  2  726f6f6d3120424f4f4b45442020200a
  3  726f6f6d31206672656520202020200a  same as block 1
  4  726f6f6d31206672656520202020200a  same as block 1
  5  726f6f6d3120424f4f4b45442020200a  same as block 2
  6  726f6f6d31206672656520202020200a  same as block 1
```

`726f6f6d31` é `room1` em ASCII. O bloco 1 é um horário livre, o bloco 2 um horário reservado, e
dali em diante o arquivo é os mesmos dois blocos em outra ordem: 32 registros, dois valores
diferentes. Arquivos reais são assim com mais frequência do que se imagina. Registros de largura
fixa, regiões zeradas de uma imagem de disco e cabeçalhos repetidos produzem blocos idênticos, e a
próxima seção mostra o que um modo de cifragem faz com eles.

## O último bloco é preenchido, sempre

A carta de encaminhamento tem 170 bytes, o que dá dez blocos completos e dez bytes a mais. Cifrada
com CBC, ela virou 176:

```
ana@lab:~/lab$ wc -c data/referral.txt referral.enc
170 data/referral.txt
176 referral.enc
346 total
```

Os seis bytes são **preenchimento** (*padding*), e a regra que o OpenSSL usa é a PKCS#7: completar o
último bloco com *n* bytes, cada um valendo *n*. Faltam seis bytes, seis bytes `06`. Na decifragem,
o último byte diz quantos remover, e um valor que não obedece à regra é o `bad decrypt` da seção
anterior.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Dois arquivos cortados em blocos AES de 16 bytes. referral.txt tem 170 bytes: dez blocos completos, depois um décimo primeiro com os últimos 10 bytes da carta e 6 bytes de preenchimento, cada um valendo 06. slots.dat tem 512 bytes, exatamente 32 blocos completos, e ainda recebe um 33º bloco de dezesseis bytes valendo 10.\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">referral.txt</text><text x=\"130\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">170 bytes = 10 × 16 + 10</text><rect x=\"20\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"64\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"84\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"108\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"152\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"196\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"240\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"284\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"328\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"372\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"392\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"416\" y=\"40\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"436\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"460\" y=\"40\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">10 bytes</text><rect x=\"536\" y=\"44\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"556\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">06×6</text><text x=\"592\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→ 176 bytes</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">slots.dat</text><text x=\"130\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">512 bytes = 32 × 16, sem resto</text><rect x=\"20\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"64\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"84\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"108\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"152\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"196\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"240\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"298\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">…</text><rect x=\"314\" y=\"128\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"334\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">32</text><rect x=\"358\" y=\"128\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"418\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">10×16</text><text x=\"494\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→ 528 bytes</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Vermelho: preenchimento. Cada byte diz quantos bytes remover.</text></svg>", "caption": "Preenchimento PKCS#7: o último bloco é sempre completado, mesmo quando os dados já o preenchem.", "same": ["170 bytes = 10 × 16 + 10", "10 bytes"]}
```

A regra não tem exceção, e é isso que a torna inequívoca. Um arquivo cujo tamanho já é múltiplo de
dezesseis também recebe preenchimento, um bloco inteiro de dezesseis bytes `10` (dezesseis, em
hexadecimal). Do contrário, um arquivo que por acaso terminasse em `01` não poderia ser distinguido
de um preenchido. O arquivo de agendamentos tem 512 bytes, exatamente 32 blocos, e seu texto
cifrado tem 528:

```
ana@lab:~/lab$ openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | wc -c
528
```

Nem todo modo preenche. **CTR e GCM transformam o AES num fluxo** (a próxima seção e a última),
então o texto cifrado tem exatamente o tamanho do texto claro. Esse é um dos motivos de os
protocolos modernos os preferirem: sem preenchimento não há erro de preenchimento, e um erro de
preenchimento que um servidor relata de forma diferente dos outros erros já bastou, mais de uma
vez, para um estranho descobrir algo sobre o texto claro. A defesa é aquela com que esta aula
termina, um modo que verifica o texto cifrado inteiro antes de decifrar qualquer coisa.

## O que dezesseis bytes significam para o tamanho dos dados

O AES cifra dezesseis bytes por vez, e o texto cifrado nunca é menor que o texto claro. O CBC
acrescenta até dezesseis bytes de preenchimento, e todo modo precisa guardar seu vetor ou nonce ao
lado do texto cifrado, o que a seção 05 desta aula explica. O GCM acrescenta uma etiqueta de
dezesseis bytes. Para uma coluna de banco de dados com um CPF, esse acréscimo é maior que o próprio
dado, e a aula 14 volta ao custo de cifrar uma coluna em vez de um disco.
