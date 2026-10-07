---
title: O four-way handshake, e o que uma gravação dele entrega
version: 1
---

**A PMK nunca atravessa o ar. Quando um aparelho entra na rede, ele e o ponto de acesso provam um ao
outro que a têm e derivam chaves novas para aquela sessão, em quatro mensagens chamadas *four-way
handshake*.** É um projeto sólido para essa tarefa. O que ele não consegue é proteger uma frase
secreta fraca, e esta seção mostra por quê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O four-way handshake entre um aparelho à esquerda e um ponto de acesso à direita, os dois já com a PMK. Mensagem 1, do ponto de acesso: o ANonce, às claras. Mensagem 2, do aparelho: o SNonce e um MIC, às claras. Mensagem 3, do ponto de acesso: o MIC dele e a chave de grupo, cifrada. Mensagem 4, do aparelho: uma confirmação. As mensagens 1 e 2 estão marcadas em vermelho como o que uma gravação captura: os dois nonces e um MIC que testa um palpite de frase secreta.\"><defs><marker id=\"hs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aparelho</text><text x=\"125\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tem a PMK</text><rect x=\"510\" y=\"20\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ponto de acesso</text><text x=\"595\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tem a PMK</text><polyline points=\"125,66 125,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"595,66 595,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><rect x=\"140\" y=\"82\" width=\"440\" height=\"104\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><polyline points=\"593,110 127,110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-amber)\"></polyline><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 ANonce</text><polyline points=\"127,160 593,160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-amber)\"></polyline><text x=\"360\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 SNonce + MIC</text><polyline points=\"593,220 127,220\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 MIC + chave de grupo (cifrada)</text><polyline points=\"127,270 593,270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"259\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 confirmação, instala as chaves</text><text x=\"360\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois derivam a PTK da PMK, do ANonce, do SNonce e dos dois endereços</text></svg>", "caption": "As mensagens 1 e 2, em vermelho, são tudo de que uma gravação precisa para testar palpites offline.", "same": ["1 ANonce", "2 SNonce + MIC"]}
```

## Quatro mensagens

1. O ponto de acesso manda um número aleatório, o **ANonce**.
2. O aparelho escolhe o próprio número aleatório, o **SNonce**. Ele já tem tudo de que precisa para
   derivar a chave da sessão, a **PTK** (*pairwise transient key*), a partir da PMK, dos dois nonces e
   dos dois endereços de hardware. Ele manda o SNonce com um **MIC**, uma verificação de mensagem
   calculada com uma parte da PTK.
3. O ponto de acesso deriva a mesma PTK, confere o MIC e assim fica sabendo que o aparelho conhecia a
   PMK. Ele responde com o próprio MIC e a **chave de grupo** (GTK), cifrada, que todo aparelho usa
   para o tráfego de difusão.
4. O aparelho confirma, e os dois instalam as chaves. Daí em diante, os quadros são cifrados com CCMP
   sob a PTK.

Toda sessão ganha uma PTK nova porque os nonces são novos. A PMK em si só serve para derivar chaves,
o papel que a chave RSA do servidor tinha no TLS antes de o Diffie-Hellman da aula 7 virar a
regra.

## O que alguém por perto grava

Tudo nas mensagens 1 e 2 vai às claras: os dois nonces, os dois endereços e um MIC. Quem está no
alcance do rádio e grava um aparelho entrando passa a ter um teste. Pega uma frase chutada, calcula a
PMK com ela e o SSID usando a função da seção anterior, deriva a PTK e calcula o MIC. Se bater com o
gravado, o chute estava certo.

**Esse teste roda offline, tão rápido quanto o hardware de quem chuta permite, e a rede nunca o vê.**
Não há login falho para contar, nem bloqueio, nem linha de log. Nada do que quem defende monitora vai
mostrá-lo. Em alguns pontos de acesso nem é preciso um cliente entrando, porque a primeira mensagem
também carrega um valor derivado da PMK. A conclusão é a mesma nos dois casos: a frase secreta precisa
resistir a palpites em velocidade máxima, por todo o tempo em que a rede a mantiver.

As contas, nos dois milhões de palpites por segundo da seção anterior:

| frase secreta | possibilidades | tempo para tentar todas |
| --- | --- | --- |
| 8 letras minúsculas | 26⁸ ≈ 2,1 × 10¹¹ | cerca de 29 horas |
| 10 letras e dígitos aleatórios | 62¹⁰ ≈ 8,4 × 10¹⁷ | cerca de 13.000 anos |
| 5 palavras aleatórias de uma lista de 7.776 | 7.776⁵ ≈ 2,8 × 10¹⁹ | cerca de 450.000 anos |

Esses números supõem uma frase **aleatória**. Uma frase que uma pessoa escolheu, como um verso de
música ou o endereço da clínica, fica no começo de qualquer lista de palpites, seja qual for o
tamanho. A regra da aula 5 vale aqui sem a rede de proteção: não há hash lento para salvar uma senha
adivinhável.

## O handshake também compartilha demais

Quem **sabe** a frase e grava o handshake de outro aparelho consegue derivar a PTK desse aparelho
também, e ler o tráfego dele. Numa rede WPA2-Personal, portanto, toda pessoa com a frase consegue
decifrar a sessão de qualquer outra que tenha visto começar. Não há sigilo futuro (*forward secrecy*):
a PMK, mais uma gravação, abre tudo. Para uma rede da recepção que leva os celulares dos pacientes,
isso é um café compartilhado. Para a equipe, que leva prontuários, não é aceitável, e é por isso que
redes de equipe usam 802.1X (aula 16) ou WPA3 (próxima seção).

## KRACK: um bug de implementação num protocolo sólido

Em 2017 a pesquisa **KRACK** mostrou que muitas implementações, quando a mensagem 3 chegava duas
vezes, instalavam a mesma chave de novo e zeravam o contador de pacotes. Esse contador é o nonce do
CCMP, então o bug era um reuso de nonce, o erro contra o qual a aula 1 avisou e ao qual a aula 17
volta. O protocolo estava certo; o código que o rodava, não. Os fabricantes corrigiram clientes e
pontos de acesso em poucos meses. A lição para quem defende é a sem graça: um aparelho que não recebe
mais atualizações continua com o bug.
