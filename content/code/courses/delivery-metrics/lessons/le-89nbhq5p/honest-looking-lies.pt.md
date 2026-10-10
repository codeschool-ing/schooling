---
title: Um catálogo de mentiras com cara de honestas
version: 1
---

Cada movimento abaixo melhora um número sem melhorar a entrega. Cada um já foi feito, em algum lugar, por pessoas que acreditavam estar fazendo a coisa razoável, e cada um pode ser defendido numa reunião. Eles estão listados para que você os reconheça, num relatório ou nos seus próprios hábitos.

## Frequência de deploy

- **Dividir um release em vários.** Fazer deploy de cada serviço, de cada mudança ou de cada arquivo de configuração separadamente, no mesmo minuto. A contagem se multiplica; os usuários recebem o mesmo código na mesma hora.
- **Fazer deploy de nada.** Uma execução do pipeline que refaz o deploy da mesma versão, ou uma mudança num comentário, conta como deploy se ninguém definiu o que é um.
- **Mudar o que conta.** Passar de "um por release" para "um por serviço" no meio de um trimestre. A aula 5 apontou essa como a definição que multiplica a métrica da noite para o dia.

## Lead time de mudanças

- **Começar o relógio mais tarde.** Medir a partir da integração em vez do primeiro commit, ou a partir do último commit antes da integração depois de fazer squash de uma semana de trabalho num só. A fila de revisão some do número.
- **Integrar cedo, fazer deploy atrás de uma flag.** Trabalho longo escondido atrás de uma feature flag pode ser integrado todo dia e reportado como rápido, enquanto a funcionalidade em si leva meses. Flags são uma boa prática; reportar as integrações como entrega é o truque.

## Taxa de falha de mudanças

- **Estreitar a definição depois do fato.** "Um rollback dentro da hora não foi bem uma falha." "Aquele incidente foi causado pelo banco de dados, não pelo deploy." Cada exclusão é plausível; juntas, elas esvaziam o numerador.
- **Corrigir para a frente sem registrar.** Um deploy quebrado seguido, vinte minutos depois, de um segundo deploy discreto que o conserta mostra dois sucessos e nenhuma falha.
- **Aumentar o denominador.** Todo truque que infla a frequência de deploy também baixa a taxa de falha, porque a taxa divide pelos deploys.

## Tempo para restaurar

- **Começar na declaração.** Se o relógio começa quando alguém declara um incidente, a hora em que ninguém percebeu desaparece.
- **Fechar o incidente na mitigação e abrir um ticket para o resto.** Às vezes é o certo, como diz a aula 14. Como hábito usado no número, isso move a recuperação para um ticket que ninguém mede.

## Métricas de fluxo

- **Dividir cartões quando envelhecem.** Um item com quarenta dias vira dois itens novos com zero, e o gráfico de envelhecimento parece renovado.
- **Tirar o trabalho travado do quadro.** Uma coluna de bloqueados fora do relógio, ou uma lista separada, como o time de Billing fez com o `BIL-189`, remove o item mais velho de todos os gráficos.
- **Fechar e reabrir.** Um bug fechado como corrigido e reportado de novo na semana seguinte conta duas vezes como vazão.

## O que eles têm em comum

Todo movimento muda **o que é contado**, não **o que acontece com o trabalho**. Isso dá o teste geral, que as duas próximas seções aplicam com um programa: **se o número se moveu, pergunte quais eventos mudaram**. Se nenhuma mudança chegou antes a um usuário, nenhuma falha foi evitada e nenhum item terminou mais rápido, o número se moveu sozinho.
