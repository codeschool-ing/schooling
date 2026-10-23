---
title: Ensaios: a noite, rodada antes da noite
version: 1
---

Um script de migração que rodou uma vez, na máquina de um desenvolvedor, contra uma amostra, provou
que consegue rodar. Não provou que termina no tempo que o negócio pode dar, que os rejeitos são
entendidos, nem que as pessoas rodando aquilo às três da manhã sabem o que fazer em seguida. **Um
ensaio é o cutover inteiro, rodado numa cópia, pelas pessoas que vão rodá-lo, contra o relógio.** A
quantidade de ensaios não é uma questão de capricho: cada um acha o que o anterior não conseguia
achar, e o plano está pronto quando um ensaio não acha nada novo.

## Dois tipos de execução

O plano da Serra Alta tinha quatro execuções, de dois tipos diferentes.

**Uma carga de teste** (*mock load*) testa o mapeamento. Ela roda a extração, a transformação e a
carga contra parte dos dados, em horário comercial, e o resultado é uma lista de rejeitos e de regras
erradas. A primeira usou 200 fazendas e um mês de histórico; a segunda, todas as fazendas e um ano.
Uma carga de teste é barata, então pode ser repetida a cada mudança da especificação.

**Um ensaio geral** (*dress rehearsal*) testa a noite. Ele roda o runbook do cutover da primeira à
última linha, numa cópia completa da produção, nos horários que o cutover de verdade vai usar, com as
pessoas citadas no runbook fazendo os próprios passos. A Serra Alta rodou dois, em noites de sábado
com três semanas de intervalo, começando às 20:00 como o de verdade. **Pelo menos dois, porque o
primeiro sempre acha alguma coisa, e o plano precisa de uma execução que não ache nada depois da
correção.**

A distinção importa porque os dois acham falhas diferentes. Uma carga de teste acha que falta uma
grafia na tabela de municípios. Só um ensaio geral acha que a extração precisa de uma senha que está
com alguém dormindo, ou que o SAP está na manutenção de domingo, das 01:00 às 05:00 (aula 1),
exatamente quando o runbook precisava dele. Também é a única execução que mostra um passo que todo
mundo achava que levava vinte minutos levando três horas no volume completo.

## O que um ensaio mede

Toda execução produz as mesmas medidas, para cada uma poder ser comparada com a anterior:

- *a duração*, passo a passo, do congelamento até o momento em que a decisão de go/no-go pode ser
  tomada;
- *os rejeitos*, por motivo, em cada passo do pipeline;
- *o resultado da reconciliação* em cada um dos níveis (a próxima seção);
- *o rollback*, cronometrado, nos ensaios gerais: depois da decisão, o time desfaz tudo e mede
  quanto tempo isso leva.

Estas são as quatro execuções da Serra Alta.

| | teste 1 | teste 2 | ensaio geral 1 | ensaio geral 2 |
|---|---|---|---|---|
| dados | 200 fazendas, um mês | todas as fazendas, um ano | cópia completa | cópia completa |
| rodado por | time de migração, de dia | time de migração, de dia | o runbook, de madrugada | o runbook, de madrugada |
| do congelamento à decisão | não cronometrado | não cronometrado | 11 h 20 min | 5 h 50 min |
| fazendas rejeitadas | 23 de 200 | 64 de 1.958 | 41 de 1.958 | 3 de 1.958 |
| coletas rejeitadas | 180 | 610 | 2.412 | 0 |
| reconciliação | só contagens | contagens e totais | contagens e totais batem; 214 linhas alteradas | limpa em todos os níveis |
| rollback | não testado | não testado | 3 h 05 min | 1 h 55 min |

Os números não caem em linha reta. O ensaio geral 1 rejeitou mais coletas do que o teste 2, porque
foi a primeira execução com o histórico inteiro. Mas cada mudança tem uma causa que alguém sabe
dizer, e é para isso que a tabela existe: **uma contagem de rejeitos que cai porque uma regra foi
corrigida é progresso; uma que cai sem ninguém saber por quê é sorte**, e pode subir de novo na noite
de verdade.

## O que o ensaio geral 1 achou

O primeiro ensaio geral falhou de quatro jeitos, e cada um deles saiu mais barato achado em julho do
que na noite do cutover.

**Foi lento demais.** A janela tem catorze horas, de sábado 20:00 a domingo 10:00. O rollback precisa
de cerca de duas horas, então a decisão de go/no-go tem de ser tomada até as 08:00 no máximo, e o
runbook reserva nove horas do congelamento até a decisão, deixando três de folga. A execução levou 11
horas e 20 minutos. Teria chegado à decisão às 07:20, com quarenta minutos de folga, e o próprio
rollback levou mais de três horas: se a resposta fosse não, o rollback iria até as 10:25, depois do
fim da janela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l14-rehearsals\" aria-label=\"Um gráfico de tempo dos dois ensaios gerais contra a janela de cutover, que vai de sábado 20:00 a domingo 10:00, catorze horas. Linhas verticais marcam o orçamento para a decisão às 05:00, a decisão mais tardia às 08:00 e o fim da janela às 10:00. Ensaio geral 1: a execução do congelamento até a decisão levou 11 horas e 20 minutos, chegando às 07:20, e o rollback levou mais 3 horas e 5 minutos, terminando às 10:25, depois da janela. Ensaio geral 2: a execução levou 5 horas e 50 minutos, chegando à 01:50, e o rollback 1 hora e 55 minutos, terminando às 03:45.\"><path d=\"M160.0 196.0 L678.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M160.0 196.0 L160.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"160.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20:00</text><path d=\"M234.0 196.0 L234.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"234.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22:00</text><path d=\"M308.0 196.0 L308.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"308.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M382.0 196.0 L382.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"382.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:00</text><path d=\"M456.0 196.0 L456.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"456.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">04:00</text><path d=\"M530.0 196.0 L530.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"530.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M604.0 196.0 L604.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"604.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><path d=\"M678.0 196.0 L678.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"678.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:00</text><text x=\"419.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">horas depois do congelamento, de sábado para domingo</text><path d=\"M493.0 44.0 L493.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M493.0 98.0 L493.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M493.0 166.0 L493.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M604.0 44.0 L604.0 66.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M604.0 98.0 L604.0 134.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M604.0 166.0 L604.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M678.0 44.0 L678.0 66.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M678.0 98.0 L678.0 134.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M678.0 166.0 L678.0 196.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"489.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orçamento</text><text x=\"604.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">decisão mais tardia</text><text x=\"678.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fim da janela</text><text x=\"150.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ensaio geral 1</text><rect x=\"160.0\" y=\"69.0\" width=\"419.3\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"579.3\" y=\"69.0\" width=\"114.1\" height=\"26.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"150.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ensaio geral 2</text><rect x=\"160.0\" y=\"137.0\" width=\"215.8\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"375.8\" y=\"137.0\" width=\"70.9\" height=\"26.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"369.6\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11 h 20</text><text x=\"641.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 h 05</text><text x=\"267.9\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 h 50</text><text x=\"411.2\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 h 55</text><rect x=\"16.0\" y=\"14.0\" width=\"26.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"21.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">execução, do congelamento à decisão</text><rect x=\"16.0\" y=\"36.0\" width=\"26.0\" height=\"14.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"48.0\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rollback, cronometrado</text></svg>", "caption": "Os dois ensaios gerais contra a janela. O primeiro chegaria à decisão com quarenta minutos de folga e não conseguiria fazer o rollback antes de a janela fechar; o segundo cabe com espaço para os dois.", "same": ["1 h 55", "11 h 20", "3 h 05", "5 h 50"]}
```

A correção que mais pesou não foi um código mais rápido. **Um mês que já foi pago não muda mais**,
então o histórico até o fim do mês anterior podia ir dias antes. No ensaio geral 2 os meses fechados
foram carregados na quarta-feira anterior e reconciliados até sexta, o que levou 6 horas e 40
minutos fora da janela; a noite em si levou só o cadastro de fazendas e o mês corrente. A carga
também passou a fazer commit em lotes de 5.000 linhas, em vez de uma linha por vez, e a criar os
índices da tabela de histórico depois da carga, e não durante. A execução da janela caiu para 5
horas e 50 minutos.

**Rejeitou 41 fazendas.** Dezenove tinham uma grafia de município que a tabela não conhecia, porque
grafias novas tinham sido digitadas desde o perfil. Das outras, 9 tinham os CPFs inválidos, 4 os
fornecedores bloqueados e 2 o documento em branco, e 7 eram as duplicadas, porque a tabela de fusões
não estava pronta. Cada motivo voltou para o seu dono, e no segundo ensaio sobravam só 3 CPFs, que o
financeiro corrigiu no Coleta na semana anterior ao cutover.

**Rejeitou 2.412 coletas, e os dados estavam certos.** O modelo do novo sistema declarava os
resultados de laboratório obrigatórios. Nessas linhas a amostra tinha se perdido ou estragado, e
nesse caso a Serra Alta paga à fazenda o preço base pelo leite: amostra perdida é um fato do negócio,
não um defeito nos dados. Cláudia assinou uma regra
nova, resultados de laboratório opcionais com um código de motivo, e as linhas entraram na execução
seguinte.

**A reconciliação passou em dois níveis e falhou no terceiro.** As contagens bateram, e o total de
litros também. A comparação registro a registro achou 214 coletas cujos litros pertenciam a outra
fazenda da mesma rota de caminhão. A transformação tinha ordenado as leituras e as fazendas
separadamente e juntado as duas pela posição em cada lista; onde duas fazendas foram coletadas numa
ordem diferente da que o arquivo de rotas listava, os litros trocaram de lugar. A próxima seção
mostra por que só o terceiro nível conseguia ver isso.

## Ensaie o rollback, não só a migração

Um plano de rollback que nunca rodou é um parágrafo. O ensaio geral 1 o rodou pela primeira vez e
ele levou 3 horas e 5 minutos, quase tudo porque ninguém tinha escrito como mandar os coletores dos
caminhões enviarem as leituras guardadas de volta ao Coleta, e não ao novo sistema. No ensaio geral 2
ele já era um script e uma lista de conferência, e levou 1 hora e 55 minutos. O runbook usa duas
horas.

**Um rollback só faz parte do plano se a duração dele foi medida.** O último momento para decidir é
o fim da janela menos o rollback, e sem a medida esse momento é um palpite.

## Quando parar de ensaiar

A regra da Serra Alta, escrita antes do primeiro ensaio geral, era simples: o cutover acontece quando
um ensaio geral completo cabe no orçamento de tempo, não rejeita nada que esteja sem dono, reconcilia
em todos os níveis e faz o rollback dentro da janela. O ensaio geral 2 cumpriu as quatro. Se não
tivesse cumprido, o plano era um terceiro ensaio duas semanas depois e um cutover um mês mais tarde,
depois do pagamento seguinte, em vez de um cutover na esperança.
