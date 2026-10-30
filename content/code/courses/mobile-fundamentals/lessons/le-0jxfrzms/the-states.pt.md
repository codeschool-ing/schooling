---
title: Os estados de uma permissão, e os dois tipos de não
version: 1
---

**Uma permissão de tempo de execução está num de poucos estados, e o estado decide se pedir de novo
mostra um diálogo ou não.** Antes de qualquer pedido ela está *não perguntada*. A pessoa responde sim
e ela fica *concedida*. A pessoa responde não, e aqui as plataformas se separam: o que vem depois de
um "não" é a única regra desta aula que difere entre elas, e é a regra que decide o quanto um app
precisa ser cuidadoso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-two-noes\" aria-label=\"O não das duas plataformas, comparado em duas linhas de passos. Android: não perguntada, depois um diálogo, depois não, depois negada com a chamada de justificativa devolvendo true, depois um segundo diálogo, depois não, depois negada de vez. iOS: não perguntada, depois um diálogo, depois não, depois negada de vez. A partir de negada de vez, nas duas, o único caminho de volta é a pessoa ligar a permissão nos Ajustes.\"><defs><marker id=\"l12-two-noes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-two-noes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"14\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Android</text><text x=\"14\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">iOS</text><rect x=\"76\" y=\"32\" width=\"84\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não perguntada</text><rect x=\"168\" y=\"32\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"203.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">diálogo</text><path d=\"M160 50 L168 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"246\" y=\"32\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"276.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não</text><path d=\"M238 50 L246 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"314\" y=\"32\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"369.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">negada</text><text x=\"369.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">rationale: true</text><path d=\"M306 50 L314 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"432\" y=\"32\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"467.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">diálogo</text><path d=\"M424 50 L432 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"510\" y=\"32\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não</text><path d=\"M502 50 L510 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"578\" y=\"32\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">negada de vez</text><path d=\"M570 50 L578 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"76\" y=\"122\" width=\"84\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não perguntada</text><rect x=\"168\" y=\"122\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"203.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">diálogo</text><path d=\"M160 140 L168 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"246\" y=\"122\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"276.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não</text><path d=\"M238 140 L246 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"578\" y=\"122\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">negada de vez</text><path d=\"M306 140 L578 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"548\" y=\"196\" width=\"156\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"626.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a pessoa a liga</text><text x=\"626.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nos Ajustes</text><path d=\"M626 158 L626 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-two-noes-ah-phosphor)\"></path><path d=\"M708 50 L715 50 L715 216 L704 216\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-two-noes-ah-phosphor)\"></path></svg>", "caption": "O Android dá mais um diálogo depois de uma recusa, e o iOS nenhum. Depois do não final, pedir não mostra nada, nas duas.", "same": ["Android", "iOS", "rationale: true"]}
```

## Android: o segundo não é final

**No Android o diálogo volta uma vez depois de uma recusa, e depois nunca mais.** A documentação do
Android sobre pedir permissões diz que, se a pessoa toca em Negar para uma permissão mais de uma vez
durante a vida do app naquele aparelho, ela não vê mais o diálogo do sistema quando o app pede de novo:
a ação "implica 'não perguntar de novo'" e "é considerada uma negação permanente". Dali em diante, um
pedido responde *negada* na hora, sem diálogo para a pessoa ver.

**Entre o primeiro não e o segundo, o Android avisa o app de que ele está nessa janela.**
`shouldShowRequestPermissionRationale()` devolve `true` depois de uma recusa, e a documentação lê isso
como o momento de mostrar a explicação do próprio app sobre por que quer a permissão, antes de pedir
pela última vez. Quando a negação fica permanente, ela volta a devolver `false`, a mesma resposta que
dá antes de qualquer pedido. Então o app não consegue distinguir "nunca perguntada" de "recusada de
vez" só por essa chamada, e precisa lembrar sozinho se já perguntou.

## iOS: o primeiro não é final

**No iOS o diálogo aparece uma vez, e o que a pessoa responder fica guardado.** A documentação da
Apple sobre pedir acesso a recursos protegidos diz que, se a pessoa nega a permissão, o acesso que
provocou a pergunta "e quaisquer tentativas seguintes" falham. A chamada de notificações diz o mesmo
com as próprias palavras: chamadas seguintes "não perguntam de novo". Não há chamada de justificativa
nem segunda chance; um app que queira se explicar precisa fazer isso *antes* do único diálogo que vai
ter.

| | Android | iOS |
|---|---|---|
| o primeiro diálogo | quando o app pede pela primeira vez | quando o app pede pela primeira vez |
| depois de um não | o diálogo pode aparecer mais uma vez | nenhum diálogo de novo |
| uma chamada que diz "explique antes" | `shouldShowRequestPermissionRationale()` | nenhuma |
| depois do não final | pedir responde *negada* na hora | pedir responde *negada* na hora |
| o caminho de volta | a pessoa a liga nos Ajustes | a pessoa a liga nos Ajustes |

## Sim, mas menos: aproximada e limitada

**As duas plataformas deixam a pessoa conceder parte do que foi pedido, e um app precisa funcionar com
essa parte.** A localização é o caso mais claro. A documentação do Android sobre permissões de
localização diz que a pessoa pode conceder a localização *aproximada*, que ela descreve como precisa
dentro de cerca de 3 quilômetros quadrados, mesmo quando o app pediu a precisa, e que o app "deve
continuar funcionando" com ela. O iOS tem a mesma escolha, informada como precisão reduzida.

**As fotos têm o próprio sim parcial.** O iOS deixa a pessoa conceder acesso *limitado* à fototeca, uma
seleção de fotos em vez de todas. O Android 14 acrescentou o *Selected Photos Access*, com o qual,
segundo a documentação, "os usuários concedem aos apps acesso a imagens e vídeos específicos". Nos dois
casos o app só vê o que foi escolhido, e a reação certa é trabalhar com essas fotos em vez de pedir o
resto.

**Um sim parcial continua sendo um sim, e o app não deve discutir com ele.** Um app que recebe a
localização aproximada e na hora pede de novo a precisa, sem nenhum motivo que a pessoa veja, está
pedindo que ela desfaça uma decisão que acabou de tomar. O planner não tem localização com que se
preocupar, mas o hábito é aquele de que esta aula inteira trata: aceitar a resposta, manter o app
funcionando, e pedir mais só quando a pessoa chegar a algo que precise disso.
