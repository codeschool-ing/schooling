---
title: O que os ensaios encontram, e o arquivo que lembra
version: 1
---

Depois da execução com o alvo em movimento, o banco ficou tranquilo e o ensaio rodou uma terceira
vez:

```
ana@vm:~$ ./restore-drill.sh > /dev/null
ana@vm:~$ cat drills.csv
when,backup,restore_s,recovery_s,verify_s,total_s,result
2026-10-10 16:50:15,20261010-164946F,2.2,2.5,6.0,16.7,ok
2026-10-10 16:50:34,20261010-164946F,3.2,2.5,6.7,17.9,DIFFERENT
2026-10-10 16:50:55,20261010-164946F,2.5,2.5,6.0,16.8,ok
```

Três linhas de histórico: dois ensaios bons e o que falhou por motivos próprios, cada um com o
backup que usou e quanto tempo levou cada fase. Ao longo dos meses esse arquivo vira o registro mais
útil que um administrador de banco de dados tem:

- **O tempo de restauração, como tendência.** As fases crescem com os dados. Uma restauração que
  levava 20 minutos em janeiro e 50 em junho vai passar da promessa da lição 8 em algum momento do
  segundo semestre, e o arquivo avisa a tempo de agir: um servidor de restauração mais rápido,
  restauração em paralelo, backups full mais frequentes para haver menos log a reaplicar.
- **O último ensaio bom.** Quando perguntam, numa auditoria ou num incidente, "quando foi a última
  vez que provamos que os backups funcionam", a resposta é uma data e uma linha, não uma lembrança.
- **As falhas, guardadas.** Um `DIFFERENT` que foi explicado, como o de cima, continua sendo uma
  linha, e a explicação fica numa nota ao lado dela.

## As falhas que os ensaios encontram de fato

Ensaios de verdade falham muito mais no caminho até os dados do que nos dados em si. Mais ou menos na
ordem de quantas vezes as equipes relatam topar com elas:

1. **Algo de que a restauração precisa não está onde o backup está**: uma chave de criptografia, uma
   senha, o arquivo de configuração da ferramenta, o diretório de um tablespace, as extensões que o
   banco usa.
2. **A máquina de restauração não está pronta**: outra versão major instalada, disco de menos, uma
   porta ou uma regra de firewall, um diretório com o dono errado.
3. **O arquivo tem um buraco**, de um período em que o arquivamento estava falhando e ninguém olhou.
4. **O procedimento está na cabeça de uma pessoa**, e o ensaio é a primeira vez que outra pessoa o
   segue.
5. **É lento demais**: a restauração funciona e leva mais tempo do que o negócio aceita esperar.
6. E às vezes, a que todo mundo imagina: **o backup está danificado.**

Só a última é uma falha de backup no sentido estrito. As outras são falhas de **recuperação**, e
cada uma delas fica invisível até alguém restaurar de propósito.
