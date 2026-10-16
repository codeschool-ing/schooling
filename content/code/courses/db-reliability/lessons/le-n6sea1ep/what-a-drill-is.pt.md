---
title: Uma restauração feita de propósito, com cronômetro
version: 1
---

As lições 1 a 6 restauraram um banco de quatro jeitos diferentes. Toda vez foi uma demonstração:
uma pessoa, uma máquina tranquila, a resposta certa conhecida de antemão. Um **ensaio de
restauração** é o mesmo ato transformado em rotina: o backup mais recente restaurado num lugar
inofensivo, com hora marcada, comprovado contra o banco em produção, cronometrado fase por fase,
registrado e jogado fora. Ele responde três perguntas que nenhuma outra verificação deste curso
responde:

- **O backup mais recente restaura?** Não o que foi testado meses atrás. Backups quebram de
  jeitos banais entre um teste e outro: uma mudança de configuração, um upgrade, um disco cheio, uma
  credencial trocada.
- **O que volta é o banco?** A comparação da lição 1, feita contra um banco que ganhou tabelas
  desde que o relatório foi escrito.
- **Quanto tempo leva?** Medido, por fase, com dados reais. A lição 8 precisa desse número, e a
  única fonte honesta dele é uma restauração que alguém cronometrou.

Um ensaio não é um teste de restauração que alguém lembra de rodar antes de uma auditoria. O valor
dele está na **repetição**: uma falha que aparece na semana em que acontece, enquanto o backup bom
anterior ainda existe, e uma duração que se vê crescer antes de virar surpresa.

## Ele já existe, na plataforma em que você está lendo isto

A escola de que este curso faz parte roda um ensaio exatamente com esse formato contra o próprio
banco de produção. Ele clona o banco a partir dos backups para um ponto no tempo num servidor novo e
temporário, roda um mesmo relatório no banco em produção e no clone, exige que as duas saídas sejam
idênticas caractere por caractere, e apaga o clone tenha a verificação passado ou falhado. As notas
dele dizem, com outras palavras, o mesmo que este curso vem dizendo: um backup declarado é uma
crença, e só uma restauração responde se os bytes voltam.

Duas decisões dele valem ser copiadas. **O relatório acha as tabelas sozinho**, então uma tabela
criada no mês que vem está no ensaio do mês que vem sem ninguém lembrar de editá-lo. E **o clone
nunca toca o servidor em produção**: a restauração é a operação destrutiva, e fazê-la por cima do
banco que está sendo testado destruiria justamente o que você precisa se a restauração saísse ruim.
Esta lição monta uma versão menor das duas coisas na sua máquina, com o segundo servidor, na porta
5433, como o lugar inofensivo.
