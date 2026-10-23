---
title: Prazos, e as exceções a eles
version: 1
---

**Cada nível da política tem um número de dias, e a data limite é contada a partir do dia em que o
achado foi feito.** Os dias em `prioritise.py` são escolha da Jatobá: sete para uma falha sendo
explorada agora, trinta para uma provável de ser ou alcançável pela rede, sessenta para uma grave que
não é, noventa para o resto. Estão na mesma faixa dos publicados. A diretiva da CISA para as agências
federais dos EUA dá duas semanas para a maioria das entradas da lista KEV, e o PCI DSS, o padrão de
pagamentos com cartão, pede patches críticos em até um mês. Um prazo que ninguém consegue cumprir é
pior que um mais longo, porque ensina às pessoas que prazos são enfeite.

A conta é do tipo que dá errado no papel, na virada de mês, então deixe um comando fazê-la:

```
ana@admin:~$ for d in 7 30 60 90; do date -d "2026-10-23 + $d days" +"%F  $d days"; done
2026-10-30  7 days
2026-11-22  30 days
2026-12-22  60 days
2027-01-21  90 days
```

## Por que a partir do dia em que foi encontrado

Uma data limite contada do dia em que alguém lê o relatório muda toda vez que o relatório é impresso de
novo. Contada do dia do achado, ela fica onde estava, e um relatório rodado em novembro diz com clareza
que algo encontrado em outubro está atrasado. **A data do achado faz parte do achado**, registrada
quando o scanner ou o script o informa pela primeira vez, e guardada.

## O que acontece na data

Três coisas podem ser verdade quando uma data limite chega, e cada uma pede uma resposta diferente:

| estado | o que acontece |
|---|---|
| corrigido, e verificado pela mesma checagem que o encontrou | fechado, com a data em que fechou |
| não corrigido, e ninguém decidiu nada | está atrasado: vai para quem responde pelo risco da máquina, pelo nome, e fica no relatório até fechar |
| ainda não corrigível: não há patch, ou o patch quebra o portal | uma **exceção**, escrita antes da data, não depois |

## Uma exceção é uma decisão com validade

Às vezes a correção não consegue sair até a data. O fornecedor não publicou uma, ou os testes da aula
17 descobrem que ela quebra alguma coisa. O que torna isso aceitável é alguém decidir, de propósito,
com um registro que um estranho consiga ler:

| campo | para o achado do nginx, por exemplo |
|---|---|
| achado | JTB-2026-02, nginx no `web` |
| motivo | o pacote corrigido quebra as configurações de proxy do portal; chamado aberto com o fornecedor |
| controle compensatório | limite de taxa na porta 80 na borda, alerta em reinícios do nginx |
| aprovado por | a pessoa que responde pelo risco do portal, pelo nome |
| validade | uma data depois da qual a exceção perde valor e o achado volta a estar atrasado |

**Uma exceção sem validade é como um achado vira permanente.** O controle compensatório importa tanto
quanto a data: uma exceção diz "ainda não conseguimos corrigir, então eis o que fazemos no lugar", e
uma que só diz "não conseguimos corrigir" é um risco aceito por omissão. A aula 17 mostra a mesma ideia
nos termos dela, como um pacote segurado de propósito.

## O que medir

Um programa de vulnerabilidades é julgado por números fáceis de coletar depois que os passos acima
existem: quantos achados estão abertos além da data limite, quanto tempo os achados levam para fechar
em cada nível, e quantas exceções estão abertas e quantas expiraram. **Vigie a contagem de atrasados,
não o total.** O total sobe toda vez que um aviso novo é publicado, o que não diz nada sobre a equipe;
a contagem de atrasados é a que a equipe controla.
