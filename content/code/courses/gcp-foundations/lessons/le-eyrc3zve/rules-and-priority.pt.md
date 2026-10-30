---
title: Uma regra, e a ordem em que as regras são lidas
version: 1
---

**Uma regra de firewall pertence a uma rede e diz, para uma direção, que tráfego permitir ou negar para que
máquinas.** Ela é global, como a rede, e é aplicada na interface de cada máquina e não numa caixa no caminho:
não há appliance de firewall para dimensionar, e duas máquinas na mesma sub-rede são filtradas uma da outra
exatamente como da internet.

Uma regra é feita de:

| parte | o que diz | o exemplo do planner |
|---|---|---|
| **direção** | `INGRESS`, tráfego chegando à máquina, ou `EGRESS`, saindo dela | entrada |
| **prioridade** | de 0 a 65535; **o número menor é lido primeiro**; 1000 se nada for dito | 1000 |
| **ação** | `allow` ou `deny` | allow |
| **protocolo e portas** | `tcp`, `udp`, `icmp`, e para os dois primeiros uma lista de portas | `tcp` 5432 |
| **origens** (entrada) ou **destinos** (saída) | faixas de endereços, ou, na entrada, as tags ou contas de serviço de outras máquinas da rede | máquinas rodando como `web` |
| **alvos** | a que máquinas a regra se aplica: todas, as que têm uma tag, ou as que rodam como uma conta de serviço | máquinas rodando como `db` |

**As regras guardam estado.** Uma regra que deixa uma conexão entrar deixa as respostas dela saírem, e uma que
deixa uma conexão sair deixa as respostas entrarem; ninguém escreve regra para a metade da volta.

## Que regra decide

Para cada pacote, o Google pega as regras que casam com ele e **a de menor número de prioridade decide**. Duas
regras na mesma prioridade com ações opostas se resolvem num sentido só: **deny ganha**. A prioridade de uma
regra não é enfeite, então. Ela é a única coisa que ordena uma lista em que a ordem é o significado.

Embaixo das regras de toda rede ficam duas que sempre estão lá, na prioridade 65535, a última possível:

- **um deny implícito de toda entrada**: o que nenhuma regra deixa entrar é recusado;
- **um allow implícito de toda saída**: o que nenhuma regra impede de sair passa.

Elas não podem ser apagadas, só sobrepostas por uma regra de número menor. Então uma rede nova em modo
personalizado, sem regra nenhuma, não aceita conexão de lugar nenhum, nem das próprias outras máquinas, e
deixa toda máquina sair. A rede padrão da lição 15 só é diferente porque é feita com quatro regras na
prioridade 65534: uma permitindo todo tráfego entre as próprias máquinas, e três permitindo SSH, RDP e ping de
qualquer lugar. **Essas três são o motivo de o planner não a usar.**

Um pouco de tráfego fica fora das regras por completo. Uma máquina sempre alcança o servidor de metadados em
`169.254.169.254`, que é de onde vêm os tokens da conta de serviço dela, lição 8; e o Google bloqueia conexões
de saída para a porta 25 em endereços externos, diga o que disser uma regra, porque uma máquina de nuvem
mandando e-mail direto é quase sempre spam.

## Regras acima da rede

As regras de uma rede não são a única camada. **Políticas de firewall** também guardam regras, e podem ser
presas à organização ou a uma pasta, a árvore da lição 2, além de a uma rede. As políticas na árvore são
avaliadas **antes** das regras da própria rede, e uma das ações delas é passar a decisão para o nível de baixo.
É assim que a equipe de segurança do planner mantém uma regra, como nada de SSH da internet na produção, que
nenhum administrador de projeto consegue sobrepor com uma prioridade 0 própria. O resto desta lição é sobre
as regras da própria rede, que são o que todo projeto escreve.
