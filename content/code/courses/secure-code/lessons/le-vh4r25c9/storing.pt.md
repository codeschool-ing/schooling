---
title: Guardar uma senha para que um vazamento valha pouco
version: 1
---

Toda decisão de projeto sobre senhas guardadas parte de uma suposição: **um dia a tabela vaza.** Um
backup legível por quem não devia, um notebook com uma cópia do banco, uma consulta no console que
trouxe mais colunas do que alguém queria. Você não planeja que aconteça; planeja quanto a cópia vale
quando acontecer.

A ideia errada vem primeiro, e soa responsável: *criptografar as senhas.* Criptografia é reversível
por natureza. Quem tem a chave lê todas as senhas de volta, e a chave mora nos mesmos servidores
que guardam a tabela, então costuma vazar junto. **Uma senha nunca é guardada numa forma que alguém
consiga transformar de volta na senha**, nem o próprio portal. O portal não precisa da senha de
volta; só precisa conferir, no login, que a digitada agora é a escolhida antes.

### Três tabelas, um vazamento

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-leak\" aria-label=\"As mesmas duas linhas da tabela de senhas, como uma cópia vazada as mostraria, guardadas de três jeitos. Texto puro: lucia e rafael mostram lilac river morning tea, legível na hora. Um hash rápido sem sal, SHA-256: as duas linhas mostram a mesma string hexadecimal, então senhas iguais ficam visíveis, e uma placa de vídeo testa bilhões de palpites por segundo. Argon2id com sal: as duas linhas são strings diferentes, cada palpite custa dezenas de milissegundos e 64 MiB de memória, e precisa ser repetido para cada paciente.\"><text x=\"126\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">texto puro</text><rect x=\"20\" y=\"40\" width=\"212\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lucia</text><text x=\"32\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lilac river morning tea</text><text x=\"32\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rafael</text><text x=\"32\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lilac river morning tea</text><text x=\"126\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">legível na hora</text><text x=\"358\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">SHA-256, sem sal</text><rect x=\"252\" y=\"40\" width=\"212\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"264\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lucia</text><text x=\"264\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">e57256…fa0c</text><text x=\"264\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rafael</text><text x=\"264\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">e57256…fa0c</text><text x=\"358\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">bilhões de palpites por segundo</text><text x=\"590\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Argon2id, com sal</text><rect x=\"484\" y=\"40\" width=\"212\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"496\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lucia</text><text x=\"496\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$argon2id$…$Qm3x…</text><text x=\"496\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rafael</text><text x=\"496\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$argon2id$…$Zr8k…</text><text x=\"590\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada palpite: ms e MiB, por paciente</text><text x=\"358\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">linhas iguais: senhas iguais</text></svg>", "caption": "O que uma cópia vazada vale depende só de como a coluna foi escrita.", "same": ["lucia", "rafael"]}
```

**Texto puro** é a falha óbvia. A segunda é a que vai para produção, porque parece a correção: um
**hash rápido** como o SHA-256. É de mão única, e a string hexadecimal não parece nada. Mas quem tem a
tabela não o reverte. Ele **chuta**: aplica o hash a um candidato, compara, passa ao próximo. O
SHA-256 foi feito para ser rápido, e uma única placa de vídeo calcula bilhões deles por segundo,
então toda senha que uma pessoa escolheria cai em horas. Sem **sal**, é pior: dois pacientes com a
mesma senha têm o mesmo hash, e um palpite quebra os dois.

A terceira tabela é a que esta aula constrói. Uma **função de hash de senha** é feita para ser lenta
e para usar memória de propósito, e mistura ao hash um **sal** aleatório, diferente para cada senha:

- **O sal** torna cada valor guardado único. Senhas iguais deixam de aparecer como linhas iguais, e
  um palpite precisa ser calculado de novo para cada paciente.
- **O custo** torna cada palpite caro. O Argon2id, a função que esta aula usa, leva dezenas de
  milissegundos e 64 MiB de memória por hash com as configurações padrão. Um paciente entrando nunca
  percebe; quem tenta um bilhão de candidatos percebe muito, e a exigência de memória é o que impede
  uma placa de vídeo de rodar milhares de palpites lado a lado.

Três funções são recomendadas para isso hoje: **Argon2id**, **scrypt** e **bcrypt**, na ordem em que a
Password Storage Cheat Sheet da OWASP as lista. Uma quarta, o PBKDF2, é a que se usa onde se exige
uma implementação validada pelo FIPS-140. MD5, SHA-1 e SHA-256 são funções de hash, e boas, para
outros trabalhos; nenhuma delas é função de hash de senha.

### O que o hash não faz

Um hash lento protege senhas **depois** de um vazamento. Não faz nada por uma senha que já era fraca,
que os primeiros palpites acham seja qual for o custo, e nada por uma senha que o paciente também
usou em outro site que vazou. Essa metade é da política, na quarta seção. E não impede alguém de
chutar **online**, pelo formulário de login: isso é limite de tentativas, um bloqueio que atrasa em
vez de travar, e um segundo fator.
