---
title: A varredura baseline do ZAP, um scanner que só lê
version: 1
---

O ZAP, Zed Attack Proxy, é um scanner de aplicações web de código aberto. As imagens Docker dele
trazem três scripts prontos: `zap-baseline.py`, `zap-full-scan.py` e `zap-api-scan.py`. **A baseline
é a que só lê.** Ela rastreia o site por até um minuto com o spider do ZAP, que segue links e preenche
formulários como um visitante faria, e depois passa as regras passivas do ZAP em cada resposta que
coletou. Passivo quer dizer que as regras olham o tráfego e não acrescentam tráfego nenhum: as
requisições são as comuns que um navegador faz, e nada é mandado para ver o que quebra.

É isso que a torna segura para rodar com frequência, e segura para rodar contra algo que você não
construiu para esse fim. É também por isso que ela acha o que acha: cabeçalhos, cookies, banners e
vazamentos, tudo legível numa resposta normal.

### O comando

Com a rede de staging da seção anterior ainda de pé, rode a varredura de um contêiner nela. O ZAP
imprime uma linha para cada regra que passou, então a saída vai para um arquivo, o shell imprime o
status de saída do ZAP, e o `grep -v ^PASS` mostra tudo menos as aprovações:

```
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 zap-baseline.py -t http://linkbox-app:8000 -z -silent > /tmp/baseline.log; echo "exit status $?"
exit status 2
ana@vm:~/linkbox$ grep -v ^PASS /tmp/baseline.log
Using the Automation Framework
Total of 4 URLs
WARN-NEW: Missing Anti-clickjacking Header [10020] x 1 
	http://linkbox-app:8000/search?q=ZAP (200 OK)
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 2 
	http://linkbox-app:8000 (200 OK)
	http://linkbox-app:8000/search?q=ZAP (200 OK)
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-app:8000/search?q=ZAP (200 OK)
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 3 
	http://linkbox-app:8000 (200 OK)
	http://linkbox-app:8000/search?q=ZAP (200 OK)
	http://linkbox-app:8000/sitemap.xml (404 Not Found)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 4	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 57
```

O comando, parte por parte:

| parte | o que faz |
|---|---|
| `--network linkbox-staging` | o scanner entra na rede privada, então alcança `linkbox-app` e nada publicado no host |
| `-t http://linkbox-app:8000` | o alvo, pelo nome dele nessa rede |
| `-z -silent` | o `-z` repassa opções ao próprio ZAP, e o `-silent` é a que importa (abaixo) |

**O `-silent` impede o ZAP de fazer requisições por conta própria.** Deixado por conta própria, o ZAP
procura uma versão mais nova quando sobe, pode baixar regras e add-ons atualizados e busca notícias
para mostrar na interface. Num job de CI, cada uma dessas coisas está errada. Precisa de uma conexão
de saída de que o job não deveria precisar. Avisa a um terceiro que você está varrendo, e quando.
Faz a varredura depender de o servidor de outra pessoa estar no ar. E um conjunto de regras
atualizado entre a execução de segunda e a de terça faria as duas discordarem por um motivo que
nenhum commit explica. Com `-silent` a varredura usa exatamente o que está na imagem,
`zaproxy/zap-stable:2.17.0`, toda vez. A regra chamada `ZAP is Out of Date [10116]` passa pelo mesmo
motivo: o ZAP nunca perguntou.

### Lendo a saída

**`Total of 4 URLs` é a primeira linha a ler**, porque ela limita tudo o que vem depois. O spider
achou a página inicial e a busca, que ele enviou com a palavra `ZAP` na caixa. As outras duas,
`robots.txt` e `sitemap.xml`, são arquivos que o ZAP pede a todo site, e o linkbox responde 404 aos
dois. Ele nunca viu `POST /links`, que pede o token, nem link curto nenhum, porque o banco está vazio.
O que estiver errado ali, esta varredura não tem como dizer.

Cada linha `WARN-NEW` é uma regra que bateu: o nome, o id entre colchetes, em quantas respostas bateu
e as URLs como evidência. **Os ids das regras são estáveis de uma execução para outra; as contagens
depois do `x` não são.** A mesma varredura rodada de novo lista uma regra numa URL a mais ou a menos,
como mostra a execução da próxima seção sobre a mesma imagem, então leia os ids e trate as contagens
como exemplos. Quatro regras bateram:

| id | regra | para que serve a proteção que falta |
|---|---|---|
| 10020 | Missing Anti-clickjacking Header | outro site poderia carregar o linkbox num frame invisível e alinhar um botão sob o clique de um visitante |
| 10021 | X-Content-Type-Options Header Missing | um navegador pode adivinhar o tipo de uma resposta pelos bytes e tratar texto como script |
| 10031 | User Controllable HTML Element Attribute | a palavra que o scanner digitou voltou dentro de um atributo HTML |
| 10038 | Content Security Policy (CSP) Header Not Set | nada limita o que a página pode carregar se marcação hostil chegar a ela |

A primeira, a segunda e a quarta são o mesmo tipo de achado: um cabeçalho que o navegador lê e que o
linkbox não manda. A terceira é diferente, e a seção da correção mostra por que é um falso positivo.
O `NEW` de `WARN-NEW` quer dizer que o achado não está marcado como em andamento num arquivo de
progresso (`-p`), que este pipeline não usa, então todo achado é novo em toda execução.

### O status de saída

A última linha conta os veredictos: nenhum FAIL, quatro WARN, 57 regras aprovadas. A baseline do ZAP
sai com um número sobre o qual um pipeline pode agir:

| status | significado |
|---|---|
| 0 | toda regra passou |
| 1 | pelo menos uma regra marcada como FAIL bateu |
| 2 | pelo menos um WARN, e nenhum FAIL |
| 3 | a própria varredura falhou, por qualquer outro motivo |

Aqui é 2. **Sem configuração, toda regra é WARN**, então a baseline como vem nunca diz FAIL: ela
relata e deixa a decisão para quem a roda. Escrever essa decisão é a próxima seção.

Terminada a varredura, derrube o staging. O script do pipeline faz o mesmo num trap, então uma
execução que falha também não deixa nada para trás:

```
ana@vm:~/linkbox$ docker rm -f linkbox-app && docker network rm linkbox-staging
linkbox-app
linkbox-staging
```
