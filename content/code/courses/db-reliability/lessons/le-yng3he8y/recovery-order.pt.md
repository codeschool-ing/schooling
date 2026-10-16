---
title: A ordem de uma recuperação, e as decisões dentro dela
version: 1
---

Uma recuperação de ransomware falha de um jeito particular: alguém restaura depressa, reconecta tudo,
e o intruso, ainda lá dentro, faz de novo na noite seguinte com o que aprendeu da primeira vez. A
ordem dos passos importa mais do que a velocidade deles, e vale a pena tê-la por escrito antes da
noite em que ela for necessária.

1. **Isolar.** Corte as máquinas afetadas da rede, e umas das outras, antes de qualquer outra coisa.
   Não as desligue a menos que quem lidera a resposta mande: uma máquina ligada guarda evidências, na
   memória e nos seus logs, que um reboot destrói.
2. **Preservar.** Guarde uma cópia do que está lá, banco danificado incluído, para a investigação e
   para qualquer obrigação legal. Um snapshot dos discos danificados basta; é evidência, não backup.
3. **Achar um lugar limpo onde restaurar.** Servidores novos, construídos do zero, com credenciais que
   nunca existiram nos antigos. Restaurar na máquina comprometida é restaurar sobre o ponto de apoio do
   intruso.
4. **Achar uma cópia limpa.** Confira os backups que você pretende usar antes de confiar neles: o
   repositório está como estava (o histórico de ensaios da lição 7 ajuda), os backups passam na
   verificação, alguma retenção ou rotina mudou recentemente. A cópia imutável da lição 9 é a que não
   pode ter sido tocada.
5. **Restaurar, e depois auditar.** Restaure até antes do dano e, antes de deixar qualquer coisa
   conectar, compare papéis, funções, configuração e regras de acesso com um inventário de antes da
   intrusão, como a seção anterior fez.
6. **Trocar todas as credenciais**, em todo lugar onde as antigas estavam guardadas, e só então
   reconectar a aplicação.
7. **Vigiar de perto por um tempo.** Os alertas desta lição, mais apertados do que o normal, por
   semanas: o intruso conhece os seus sistemas e pode tentar de novo.

## Quem decide o quê

A maioria desses passos não é decisão só do administrador de banco de dados. Se um sistema de
produção deve ser isolado, se a polícia ou um regulador devem ser envolvidos, se e como avisar os
clientes, e se vale pagar, são decisões de quem lidera a organização, normalmente com advogados e
especialistas em resposta a incidentes. O que o administrador de banco de dados traz são os fatos que
tornam essas decisões possíveis: **que cópias existem, quais se sabe que estão limpas, até quando elas
voltam, e quanto tempo uma restauração leva**, tudo medido nas lições anteriores deste curso, e não
chutado na hora.

A lição 22 trata um incidente como um todo: detectar, decidir, comunicar e escrever sobre ele depois.
O ransomware é o incidente em que cada parte disso está sob mais pressão, e em que ter ensaiado mais
aparece.

## Ensaiando

Um **exercício de mesa** (tabletop) percorre os passos acima com as pessoas que os executariam, em
volta de uma mesa, contra um cenário inventado, sem tocar em nenhum sistema: os backups foram apagados
às 02:00 do último domingo, o banco foi sobrescrito na quarta à noite, o que fazemos agora, e quem
faz. Custa uma tarde, e acha as lacunas que um script não acha: o telefone que ninguém tem, a conta
de nuvem em que só uma pessoa consegue entrar, a passphrase que acaba se revelando guardada no próprio
servidor que está sendo restaurado.

Junte isso, uma vez por ano, a uma restauração de verdade a partir da cópia imutável, em servidores
limpos, feita por alguém que não configurou os backups, e a organização terá feito, antes do ataque,
a coisa mais difícil que de outro modo teria que fazer pela primeira vez durante um.
