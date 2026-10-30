---
title: O que cada sistema deixa um app fazer em segundo plano
version: 1
---

**Um app fora da tela não decide quando roda.** Num notebook, um programa em segundo plano segue
até terminar. Num celular, o sistema o para, o congela ou o deixa rodar em momentos que ele escolhe,
e as duas plataformas apertam essas regras em quase toda versão. Os detalhes mudam e o princípio
não. **Trabalho que não é para a pessoa olhando a tela roda quando o sistema manda, num lote junto
com o de todo mundo.**

Tudo abaixo foi lido na documentação de cada plataforma em 30 de outubro de 2026. Isso muda, então
os cursos depois da bifurcação leem de novo para a versão deles.

## Android: Doze, standby buckets e o trabalho que espera

**Doze é o que um celular faz quando ninguém está mexendo nele.** A página do Android sobre Doze e
App Standby o descreve: quando o aparelho está fora da tomada, parado e com a tela apagada por um
tempo, os apps perdem o acesso à rede, os wake locks deles são ignorados, e os jobs, as
sincronizações e os alarmes comuns são adiados. De tempos em tempos o sistema abre uma *janela de
manutenção* curta, em que todo esse trabalho adiado roda e a rede fica disponível, e depois a fecha
de novo, e as janelas ficam mais espaçadas quanto mais tempo o celular fica parado. Mexer no
celular, acender a tela ou ligar o carregador encerra o Doze.

**Os App Standby Buckets classificam cada app por quão recente e quão frequentemente ele é usado**,
a partir do Android 9. O bucket decide com que frequência os jobs de um app podem rodar e os alarmes
podem disparar, e a documentação cita cinco, mais um bucket especial para apps instalados e nunca
abertos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l15-buckets\" aria-label=\"Os App Standby Buckets do Android como uma escada, das menores restrições às maiores. Active: o app está em uso ou foi usado há pouquíssimo tempo; restrições mínimas. Working set: em uso regular; restrições leves. Frequent: usado com frequência, não todo dia; restrições mais fortes. Rare: pouco usado; restrições rígidas em jobs, alarmes e rede. Restricted: consome muitos recursos, ou, a partir do Android 13, não é aberto há 8 dias; jobs uma vez por dia numa sessão agrupada de dez minutos. Fora da escada, um bucket never para apps instalados e nunca abertos.\"><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">bucket</text><text x=\"180\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">o app está</text><text x=\"470\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">restrições</text><rect x=\"20\" y=\"34\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">active</text><rect x=\"170\" y=\"34\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em uso, ou usado há pouquíssimo</text><rect x=\"460\" y=\"34\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mínimas</text><rect x=\"20\" y=\"74\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">working set</text><rect x=\"170\" y=\"74\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em uso regular</text><rect x=\"460\" y=\"74\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">leves</text><rect x=\"20\" y=\"114\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">frequent</text><rect x=\"170\" y=\"114\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">usado com frequência, não todo dia</text><rect x=\"460\" y=\"114\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mais fortes</text><rect x=\"20\" y=\"154\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rare</text><rect x=\"170\" y=\"154\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pouco usado</text><rect x=\"460\" y=\"154\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rígidas: jobs, alarmes, rede</text><rect x=\"20\" y=\"194\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">restricted</text><rect x=\"170\" y=\"194\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pesado em recursos, ou 8 dias sem abrir</text><rect x=\"460\" y=\"194\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">jobs 1 vez ao dia, 10 minutos</text><text x=\"710\" y=\"20\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">mais restrito ↓</text><text x=\"20\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">e um bucket never, para apps instalados e nunca abertos: severas</text></svg>", "caption": "O sistema move um app entre os buckets conforme ele é usado, e cada fabricante pode definir os próprios critérios. Um app não escolhe o seu bucket; só pode se comportar bem em todos eles.", "same": ["bucket"]}
```

Duas linhas daquela página merecem ser lidas duas vezes. **Cada fabricante pode definir as próprias
regras de em qual bucket um app cai**, e o conselho não é tentar influenciar isso, e sim se
comportar bem em qualquer um deles. E a partir do Android 13, um app que o usuário não abre há 8 dias
vai para *restricted*, onde os jobs dele rodam uma vez por dia numa sessão agrupada de dez minutos,
junto com os jobs de outros apps.

**Um serviço em primeiro plano é o único jeito de continuar rodando à vista, e ele leva uma
notificação que o usuário consegue ver.** Música, uma corrida sendo registrada, navegação: trabalho
que o usuário iniciou e conhece. A partir do Android 14, um app precisa declarar um *tipo* para cada
serviço em primeiro plano, como localização, reprodução de mídia, sincronização de dados ou saúde, e
pedir a permissão correspondente. Sem isso, o sistema lança uma exceção quando o serviço começa.

**Todo o resto passa pelo WorkManager**, que roda trabalho que precisa sobreviver ao app fechado. Ele
aceita *restrições*: rodar só numa rede não tarifada, só carregando, só com a bateria não baixa, só
com o aparelho ocioso. Existe trabalho periódico, e o menor intervalo que ele aceita é **15
minutos**. Mesmo assim, a documentação é cuidadosa: o intervalo é o tempo mínimo entre execuções, e
o momento exato depende das restrições e do sistema.

## iOS: poucos modos com nome, e tarefas na hora que o sistema escolhe

**O iOS dá a um app em segundo plano uma lista curta de coisas que ele pode fazer, e o suspende fora
disso.** Um app declara no projeto os *background modes* de que precisa, e cada um é um trabalho
específico: tocar áudio, receber atualizações de localização, uma chamada de voz, background fetch,
background processing. Um app sem nenhum deles é suspenso pouco depois de sair da tela.

**Trabalho adiado passa pelo `BGTaskScheduler`, em dois tipos.** Um `BGAppRefreshTaskRequest` pede
uma atualização curta, como buscar a semana mais recente. Um `BGProcessingTaskRequest` pede uma
tarefa mais longa, minutos em vez de segundos, e pode exigir energia externa e conexão de rede, que é
o que uma manutenção de banco de dados ou um upload grande deveria pedir. Cada identificador de
tarefa precisa estar listado no `Info.plist` do app, e o app registra o handler dele ao iniciar.

**E o iOS não promete nada sobre quando.** Um pedido leva um `earliestBeginDate`, e a documentação
da Apple sobre ele diz que o sistema não garante iniciar a tarefa naquela data, só que ela não vai
começar antes. O sistema pesa a bateria, a rede e o jeito como o usuário usa o app. Uma tarefa que
precisa rodar às 08:00 em ponto não é uma tarefa em segundo plano no iOS; a aula 17 mostra o que é.

## O React Native pega emprestado dos dois

**Um app React Native roda nos mesmos dois sistemas, com as mesmas regras.** Ele não tem mecanismo
próprio de segundo plano: bibliotecas embrulham os nativos. O `expo-background-task` da Expo, lido na
documentação no mesmo dia, usa o WorkManager no Android e o `BGTaskScheduler` no iOS. As tarefas
dele dividem um único worker, esperam pelo menos 15 minutos entre execuções no Android, e só rodam
quando a bateria tem carga suficiente e há rede disponível. O React Native também tem o *headless
JS*, um jeito de o Android rodar JavaScript sem tela, e ele obedece aos mesmos limites.

| | Android | iOS | React Native |
|---|---|---|---|
| trabalho adiado, em lote | WorkManager, com restrições | `BGTaskScheduler`: app refresh ou processing | `expo-background-task`, sobre os dois |
| menor repetição | 15 minutos | nenhuma prometida: o sistema decide | 15 minutos no Android, a escolha do sistema no iOS |
| rodando à vista | um serviço em primeiro plano, com notificação e tipo declarado | um background mode, como áudio ou localização | o da própria plataforma, por uma biblioteca |
| quando o usuário deixa o celular em paz | Doze, e o standby bucket | o app é suspenso | o do sistema em que roda |
