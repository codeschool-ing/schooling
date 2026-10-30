---
title: Estar online não é sim ou não
version: 1
---

**A imagem com que quase todo mundo começa é um interruptor: o celular está online ou offline, e o
app confere qual dos dois antes de pedir alguma coisa.** A rede de um celular não se comporta
assim. Ela muda debaixo do app muitas vezes por dia, e a maioria das mudanças não a deixa nem
claramente ligada nem claramente desligada. Vale conhecer cinco delas pelo nome, porque cada uma
falha de um jeito diferente.

| o que acontece | o que o sistema informa | o que a requisição do app encontra |
|---|---|---|
| a aluna sai de casa, e o Wi-Fi passa a vez para os dados móveis | a rede padrão muda | uma requisição na rede antiga morre no meio, com um erro ou com silêncio |
| um elevador, um túnel, o fundo de um estacionamento | muitas vezes ainda há uma rede, sem sinal por trás | silêncio: nada recusa, nada responde |
| modo avião | nenhuma rede | um erro na hora, que é o caso fácil |
| o Wi-Fi de um café que pede login antes | uma rede Wi-Fi, mas não validada | uma resposta da página de login do café, não do seu servidor |
| dados móveis com uma franquia mensal pequena | uma rede marcada como tarifada | funciona, e cada megabyte custa dinheiro ao usuário |

**O modo avião é a única linha em que "offline" é a palavra certa**, e é a que menos dá trabalho: a
requisição falha num milissegundo e o app consegue dizer isso. As linhas que doem são aquelas em
que existe uma rede. No elevador o celular ainda mantém uma conexão com a antena, a requisição sai,
e nada volta. O app não fica sabendo que falhou. Ele não fica sabendo de nada, e espera.

**O portal cativo é o mais estranho dos cinco.** O celular entrou no Wi-Fi do café, a rede está de
pé, e toda requisição para qualquer endereço recebe resposta, da página do próprio café pedindo que
o usuário aceite os termos. Um app que confia em "conectado" e lê a resposta como o seu JSON falha
num lugar inesperado, num erro de parse sobre uma página HTML.

## O que o sistema consegue dizer

**As duas plataformas deixam o app perguntar sobre a rede, e as duas respondem uma pergunta mais
estreita do que parece.** A documentação do Android sobre ler o estado da rede, lida em 30 de
outubro de 2026, é explícita. Uma rede com a capacidade `INTERNET` é uma rede *configurada* para
chegar à internet, e isso, diz a página, não é a capacidade real de alcançar servidores públicos; o
exemplo que ela dá é um portal cativo. O mais próximo disso é `VALIDATED`, que o sistema marca
quando uma sondagem dele mesmo alcançou a internet, e a mesma página avisa que uma rede validada
ainda pode perder a conexão por causa de sinal fraco. O iOS informa o `status` de um caminho, e se
ele é *caro*, ou seja, dados móveis ou um hotspot pessoal, ou *restrito*, quando o usuário ligou o
Modo Pouco Uso de Dados.

Os três trechos abaixo se registram para saber das mudanças de rede, um por plataforma. Foram
adaptados do guia do Android sobre estado da rede, da referência da Apple para `NWPathMonitor` e do
README da biblioteca `@react-native-community/netinfo`, e **não foram compilados nem executados
para este curso**:

```kotlin
val cm = context.getSystemService(ConnectivityManager::class.java)
cm.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) { /* a default network exists */ }
    override fun onLost(network: Network) { /* and now it does not */ }
    override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
        val probed = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        val free = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
    }
})
```

```swift
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    let usable = path.status == .satisfied
    let costly = path.isExpensive      // mobile data, or a personal hotspot
    let lowData = path.isConstrained   // the user turned on Low Data Mode
}
monitor.start(queue: DispatchQueue(label: "network"))
```

```tsx
import NetInfo from "@react-native-community/netinfo";

const unsubscribe = NetInfo.addEventListener((state) => {
  const connected = state.isConnected;           // a network exists
  const reachable = state.isInternetReachable;   // null until a check has answered
  const costly = state.details?.isConnectionExpensive;
});
```

**Nenhum dos três sabe qualquer coisa sobre o seu servidor.** "A internet está alcançável" quer
dizer que uma sondagem chegou ao Google, ou à Apple, ou ao endereço que a biblioteca tiver
configurado; o README do NetInfo cita `https://clients3.google.com/generate_204` como o padrão. O
seu servidor pode estar fora do ar, lento ou bloqueado enquanto todas essas flags dizem sim.

## Então para que servem

**Use o estado da rede para decidir se vale tentar, e o que tentar. Nunca como veredito.** Três
usos se sustentam:

- **Esperar por uma rede que não existe.** Sem rede nenhuma, não adianta mandar a requisição; o app
  pode esperar o `onAvailable`, ou o caminho ficar satisfeito, e mandar nessa hora.
- **Respeitar o custo.** Numa rede tarifada ou restrita, o planner pode atualizar a semana, que são
  algumas centenas de bytes, e deixar o download dos vídeos de um curso para o Wi-Fi.
- **Tentar de novo quando a rede volta.** Uma requisição que falhou no elevador merece ser enviada
  de novo no instante em que o sistema informa uma mudança, e não num cronômetro.

O único teste de que o seu servidor responde é uma requisição ao seu servidor, com um limite de
quanto tempo você espera por ela. O resto desta aula constrói essa requisição contra um servidor
que se comporta mal de propósito.
