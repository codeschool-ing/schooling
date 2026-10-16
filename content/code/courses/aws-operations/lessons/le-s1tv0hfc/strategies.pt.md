---
title: Quatro jeitos de trocar uma versão em execução
version: 1
---

Um deploy troca a versão 1.4.0 pela 1.4.1 enquanto os clientes usam o serviço. A imagem de que a
maioria das pessoas parte é um interruptor: desliga a antiga, liga a nova. **Toda estratégia que vale
a pena usar mantém as duas versões rodando por um tempo**, e as estratégias diferem em como o tráfego
passa de uma para a outra e em quão rápido ele consegue voltar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro gráficos pequenos da fatia do tráfego na versão nova ao longo de quinze minutos. O rolling sobe em degraus de 20% a cada dois minutos, misturando versões o tempo todo. O blue/green de uma vez salta de 0 a 100% num movimento só, e volta em segundos. O canário fica em 10% por cinco minutos e depois salta para 100%. O linear sobe 10% por minuto até 100% no minuto 9.\"><defs><marker id=\"stg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">rolling</text><path d=\"M46 58 L46 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M46 178 L166 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"42\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"42\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"166\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M46.0 178.0 L62.0 154.0 L78.0 130.0 L94.0 106.0 L110.0 82.0 L126.0 58.0 L166.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"100.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">versões misturadas o tempo todo</text><rect x=\"195\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">blue/green, tudo de uma vez</text><path d=\"M221 58 L221 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M221 178 L341 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"217\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"217\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"341\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M221.0 178.0 L229.0 178.0 L229.0 58.0 L341.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"275.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um movimento, volta em segundos</text><rect x=\"370\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">canário 10%, 5 min</text><path d=\"M396 58 L396 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M396 178 L516 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"392\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"392\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"516\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M396.0 178.0 L396.0 166.0 L436.0 166.0 L436.0 58.0 L516.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"450.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um teste pequeno, depois tudo</text><rect x=\"545\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">linear 10% por minuto</text><path d=\"M571 58 L571 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M571 178 L691 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"567\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"567\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"691\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M571.0 178.0 L571.0 166.0 L579.0 154.0 L587.0 142.0 L595.0 130.0 L603.0 118.0 L611.0 106.0 L619.0 94.0 L627.0 82.0 L635.0 70.0 L643.0 58.0 L651.0 58.0 L691.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"625.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">passos iguais</text></svg>", "caption": "A fatia do tráfego na versão nova, minuto a minuto, em cada estratégia.", "same": ["rolling"]}
```

**No lugar, ou rolling.** As próprias tarefas do serviço são trocadas algumas por vez: para uma antiga,
sobe uma nova, repete. Não precisa de capacidade extra, e é o padrão do próprio ECS para um serviço. A
fraqueza dele é o caminho de volta: reverter é outro deploy rolling, da versão antiga, no mesmo
ritmo, e durante todo esse tempo o serviço roda uma mistura.

**Blue/green.** Um segundo conjunto completo de tarefas, o verde, sobe ao lado do azul que está
atendendo. Nada chega ao verde até ele estar saudável; aí o listener do balanceador passa do target
group azul para o verde. **Reverter é voltar o listener**, o que leva segundos, porque o azul continua
rodando. O preço é capacidade dobrada enquanto o azul for mantido.

**Canário.** Blue/green, com a passagem feita em dois passos: primeiro uma fatia pequena do tráfego,
digamos 10%, por um tempo fixo, e depois o resto. A fatia pequena é um teste com usuários reais e dano
limitado.

**Linear.** Blue/green, com a passagem feita em passos iguais: 10% a mais a cada minuto, ou a cada
três, até o verde ter tudo. Ele espalha o risco pelo deploy inteiro em vez de concentrar a evidência
numa janela inicial.

## Os nomes que o CodeDeploy dá a elas

Para o ECS, o CodeDeploy só faz blue/green, e a estratégia é uma **configuração de deploy**, um nome a
que o deployment group se refere. As predefinidas são:

| configuração | o que ela faz |
|---|---|
| `CodeDeployDefault.ECSAllAtOnce` | todo o tráfego para o verde de uma vez |
| `CodeDeployDefault.ECSCanary10Percent5Minutes` | 10%, e o resto depois de 5 minutos |
| `CodeDeployDefault.ECSCanary10Percent15Minutes` | 10%, e o resto depois de 15 minutos |
| `CodeDeployDefault.ECSLinear10PercentEvery1Minutes` | 10% a mais a cada minuto |
| `CodeDeployDefault.ECSLinear10PercentEvery3Minutes` | 10% a mais a cada três minutos |

Uma equipe pode definir a sua, digamos 5% por 30 minutos, com `create-deployment-config`. O moto não
implementa configurações de deploy, então nem esse comando nem uma listagem das predefinidas foi
executado para este curso; a tabela é a documentação da AWS.

Qual escolher não é questão de gosto, e a seção depois da próxima conta por quê: **um canário só é
tão bom quanto o alarme que o vigia**, e o alarme errado deixa um canário pior do que canário nenhum.
