---
title: Comentários que fazem a falha ser corrigida
version: 1
---

Achar uma falha é metade de uma revisão. A outra metade é um comentário que faz ela ser corrigida, por
um colega ocupado que acredita que a mudança está boa. **Um comentário que funciona diz o que
acontece, mostra, propõe uma saída e diz quanto importa.** Um que só diz *"inseguro"* começa uma
discussão.

### Quatro partes

| parte | o que faz | para o achado 1 |
|---|---|---|
| **o que acontece** | uma consequência concreta, numa frase | "Qualquer paciente autenticado lê qualquer mensagem trocando o número no endereço." |
| **a evidência** | a linha, e como ver | "`read_message` nunca compara `MESSAGES[number]['patient']` com `patient()`." |
| **uma saída** | uma correção, ou o teste que a fixaria | "Responder 404 quando não for de quem chama, como a rota de cancelar faz, e acrescentar um teste de que a lucia não lê a mensagem 2." |
| **quanto importa** | bloqueante, ou não | "Bloqueante: expõe mensagens de outros pacientes." |

Escrito assim, o comentário pode ser resolvido sem reunião, e o autor pode discordar de algo
específico.

### Pergunte sobre intenções, afirme fatos

Alguns achados são certos e outros dependem do que o autor quis. "Isto expõe mensagens de outros
pacientes" é um fato sobre o código; diga sem rodeios. "O campo `patient` no formulário era para a
equipe enviar em nome de alguém?" é uma pergunta sobre intenção; pergunte. Se a resposta for sim, a
correção é outra (uma rota da equipe com verificação própria) e o comentário evitou uma correção
errada.

### Diga o que bloqueia, e seja breve

Uma revisão com vinte comentários de peso igual esconde os dois que importam. Marque os que precisam
mudar antes do merge, e rotule o resto como sugestão. O achado 1 bloqueia; o número de mensagem
duplicado é sugestão. **O autor lê os comentários bloqueantes primeiro**, e quem decide se aprova
também deveria.

### Aprovar é uma declaração

"Para mim está bom" numa mudança com uma rota que lê dados de outras pessoas é uma declaração que o
revisor fez, não só o autor. Aprove o que você leu, diga o que não leu ("não conferi as mudanças do
template") e deixe a mudança sem aprovação se houver um achado bloqueante em aberto.
