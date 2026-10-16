---
title: O que o app guarda quando o Android o tira de cena
version: 1
---

**Um app num celular não está aberto ou fechado. O Android o move entre estados, e pode encerrar o
processo dele sem pedir licença.** A pessoa aperta Home, e o Tickets vai para o segundo plano, ainda
na memória. Outro app precisa dessa memória, e o Android mata o processo do Tickets enquanto ele
espera ali. A pessoa volta pela lista de apps recentes. O Android inicia um processo novo e
reconstrói a tela que ela deixou, a partir do que o antigo salvou. Para a pessoa, nada aconteceu.
Para o app, tudo o que ele tinha na memória sumiu.

A crença comum é a de que isso é raro e coisa de celular velho. Acontece com todo app, todo dia, em
qualquer celular que fica sem memória. E uma segunda família de eventos faz o mesmo com uma tela
só. **Girar o celular, mudar para o tema escuro, trocar o idioma ou o tamanho da fonte destrói a
activity e cria uma nova.** A nova fica no mesmo processo, e se desenha para a configuração nova.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro estados em fila. Na frente, resumed; o botão Home manda o app para o segundo plano, parado e ainda na memória; o am kill encerra o processo enquanto ele espera ali, embora o app continue em Recentes; o ícone o traz de volta, reconstruído num processo novo. Embaixo, uma rotação ou uma troca de tema destrói a tela e a cria de novo no mesmo processo. Uma tela reconstruída recebe de volta o intent com os extras e o que as views salvaram, como uma chave e a posição da rolagem, e perde o que o código pôs numa view e, depois da morte do processo, tudo o que estava na memória.\"><defs><marker id=\"f21states-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">na frente</text><text x=\"90\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">resumed</text><rect x=\"200\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">em segundo plano</text><text x=\"270\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">parado, na memória</text><rect x=\"380\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">processo morto</text><text x=\"450\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">ainda em Recentes</text><rect x=\"560\" y=\"70\" width=\"140\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reconstruído</text><text x=\"630\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um processo novo</text><line x1=\"160\" y1=\"90\" x2=\"200\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"180\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">HOME</text><line x1=\"340\" y1=\"90\" x2=\"380\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">am kill</text><line x1=\"520\" y1=\"90\" x2=\"560\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"540\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o ícone</text><rect x=\"380\" y=\"160\" width=\"320\" height=\"120\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma tela reconstruída recebe de volta</text><text x=\"540\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o intent dela, com os extras</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o que as views salvaram: uma chave, a rolagem</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">perde o que o código pôs numa view,</text><text x=\"540\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">e, depois da morte do processo, toda a memória</text><line x1=\"630\" y1=\"124\" x2=\"630\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><rect x=\"20\" y=\"200\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma rotação, um tema</text><text x=\"110\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">destruída e criada de novo</text><line x1=\"200\" y1=\"226\" x2=\"376\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"288\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mesmo processo</text><line x1=\"90\" y1=\"124\" x2=\"90\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21states-ah)\"></line><text x=\"98\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">girou</text></svg>", "caption": "Dois caminhos até uma tela reconstruída. Uma rotação mantém o processo, então os objetos na memória sobrevivem; a morte do processo não, e só o estado salvo volta.", "same": ["resumed"]}
```

## O que sobrevive, em geral

Quando o Android recria uma activity, por uma rotação ou depois que o processo dela foi morto, a nova
recebe três coisas da antiga:

- o intent com que ela foi iniciada, com os extras;
- o estado que as views salvam sozinhas. Uma view com `android:id` salva o que a pessoa mudou
  nela: se uma chave está ligada, o texto digitado num campo, até onde uma lista foi rolada. Ela não
  salva o que o código pôs nela: um texto, uma cor, se está visível;
- o que a própria activity salvou em `onSaveInstanceState`, um método que o Tickets não tem.

Arquivos e `SharedPreferences` estão no disco e sobrevivem a tudo menos a uma desinstalação.
**Qualquer outra coisa na memória sobrevive a uma rotação e não a uma morte de processo**: campos de
um `object` do Kotlin, caches, contadores.

## O que o Tickets guarda, lido do código dele

```
ana@laptop:~/boxoffice$ grep -n 'getSharedPreferences\|getStringExtra\|getIntExtra\|var baseUrl\|visibility =' tickets/app/src/main/java/example/tickets/*.kt
tickets/app/src/main/java/example/tickets/MainActivity.kt:50:        banner.visibility = View.GONE
tickets/app/src/main/java/example/tickets/MainActivity.kt:51:        error.visibility = View.GONE
tickets/app/src/main/java/example/tickets/MainActivity.kt:57:                banner.visibility = View.VISIBLE
tickets/app/src/main/java/example/tickets/MainActivity.kt:61:                error.visibility = View.VISIBLE
tickets/app/src/main/java/example/tickets/ShowActivity.kt:20:        findViewById<TextView>(R.id.title).text = intent.getStringExtra("title")
tickets/app/src/main/java/example/tickets/ShowActivity.kt:21:        findViewById<TextView>(R.id.time).text = intent.getStringExtra("time")
tickets/app/src/main/java/example/tickets/ShowActivity.kt:22:        findViewById<TextView>(R.id.price).text = intent.getStringExtra("price")
tickets/app/src/main/java/example/tickets/ShowActivity.kt:24:            getString(R.string.seats_left, intent.getIntExtra("seats", 0))
tickets/app/src/main/java/example/tickets/ShowActivity.kt:42:        denied.visibility = if (granted) View.GONE else View.VISIBLE
tickets/app/src/main/java/example/tickets/Shows.kt:35:    var baseUrl = "http://10.0.2.2:8080"
tickets/app/src/main/java/example/tickets/Shows.kt:52:        val saved = context.getSharedPreferences("shows", Context.MODE_PRIVATE)
```

Posta ao lado das regras acima, essa saída prevê o que cada evento faz com o Tickets. É uma
previsão, feita a partir do código, e são os testes da seção 05 que a conferem:

| | uma rotação | o processo morto em segundo plano |
|---|---|---|
| **a lista** | o `onCreate` roda de novo, então os espetáculos são buscados de novo: uma segunda requisição, e a faixa calculada de novo | o mesmo |
| **a cópia salva** (`getSharedPreferences`, `Shows.kt` linha 52) | mantida | mantida: é um arquivo |
| **título, horário, preço e lugares de um espetáculo** (linhas 20 a 24) | mantidos: vêm do intent | mantidos, do intent; os lugares são o número do momento do toque, nunca atualizado |
| **a chave de lembrete** | mantida: um `Switch` com id salva se está ligado | mantida, do mesmo jeito |
| **a linha `remind_denied`** (linha 42) | **perdida**: a visibilidade dela foi definida por código, e a view não a salva | perdida |
| **`Shows.baseUrl`** (linha 35) | mantido | de volta a `http://10.0.2.2:8080`: um processo novo começa o objeto de novo |

**Uma das linhas é um defeito.** Uma pessoa que recusou as notificações e depois gira o celular vê a
chave desligada, e não vê mais a frase dizendo por quê. A tabela da seção 03 chamou esse de o estado
que um app precisa explicar. E nada no código recarrega a lista quando a pessoa volta do segundo
plano, então os lugares na tela podem ter horas de idade. Essa é uma questão
de produto a levantar mais do que um defeito, já que o botão Atualizar está ali.

## Movendo o app entre estados com o adb

No emulador da lição 14, num terminal, com o Tickets aberto na tela do espetáculo:

```sh
adb shell input keyevent KEYCODE_HOME
adb shell am kill example.tickets
adb shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n example.tickets/.MainActivity
adb shell am force-stop example.tickets
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 1
```

A primeira linha aperta Home. A segunda mata o processo do app, e só se ele estiver em segundo plano,
que é o que o próprio Android faz quando precisa de memória. A terceira manda o intent que o ícone do
app manda. Ela traz de volta a tarefa com a tela do espetáculo reconstruída por cima. **`force-stop` é
diferente de `kill`.** É o que *Forçar parada*, nas configurações do app, faz, uma decisão da pessoa
de encerrar o app, e o Android não restaura nada depois. A próxima abertura é a frio, na lista. As
duas últimas desligam a rotação automática e põem a tela em paisagem; `user_rotation 0` a devolve.
Nenhum desses comandos foi rodado para este curso: o adb da máquina de gravação não tem aparelho
para onde mandá-los.

À mão, as *Opções do desenvolvedor* têm uma chave chamada *Não manter atividades*, que destrói toda
activity no momento em que ela sai da tela. É um jeito rápido de achar uma tela que perde alguma
coisa, só com o polegar.

## O mesmo pelo Appium

O driver UiAutomator2 tem um comando `mobile:` para cada movimento, chamado por `driver.execute`:

| comando | o que faz |
|---|---|
| `mobile: backgroundApp`, `{ seconds: 5 }` | Home, e volta depois de cinco segundos; um número negativo deixa o app em segundo plano |
| `mobile: activateApp`, `{ appId }` | traz o app para a frente, como o ícone dele |
| `mobile: terminateApp`, `{ appId }` | `force-stop`: não é uma morte de processo, já que nada é restaurado |
| `mobile: queryAppState`, `{ appId }` | `0` não instalado, `1` não rodando, `3` em segundo plano, `4` na frente |
| `driver.setOrientation('LANDSCAPE')` | gira a tela; um comando mais antigo do WebDriver que o Appium manteve, não um `mobile:` |

**Uma morte de processo precisa de `am kill`, que o Appium só consegue mandar por um shell no
aparelho**, o `mobile: shell`. Um shell no aparelho roda qualquer comando. Então o Appium o recusa a
menos que o servidor tenha sido iniciado com `--allow-insecure` nomeando esse recurso. Pare antes o
servidor da lição 15 com Ctrl-C. Com o recurso nomeado sozinho, do jeito que guias mais antigos
escrevem, o Appium 3 se recusa a iniciar:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1 --allow-insecure adb_shell 2>&1 | grep '^Error'
Error: The full feature name must include both the destination automation name or the '*' wildcard to apply the feature to all installed drivers, and the feature name split by a colon. Got 'adb_shell' instead
```

Ele quer o recurso nomeado junto com o driver a que se destina:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1 --allow-insecure uiautomator2:adb_shell
[Appium] Non-default server args:
[Appium] { address: '127.0.0.1', allowInsecure: [ 'uiautomator2:adb_shell' ] }
[Appium] Appium REST http interface listener started on http://127.0.0.1:4723
```

Esse servidor vai rodar comandos de shell para qualquer cliente que o alcance. É por isso que a
lição 15 o prendeu a `127.0.0.1`, e por isso um servidor compartilhado num escritório ou numa nuvem de
aparelhos não deve ser iniciado assim. Inicie desse jeito só para o teste que precisa.
