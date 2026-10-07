---
title: Drift, e a mudança que ninguém anotou
version: 2
---

Uma semana depois, alguém precisa olhar, de casa, um dos servidores da loja e abre SSH para o mundo no
security group, de outra máquina, à mão. É um comando, com o id do grupo em `SG`, e resolve o
problema do dia:

```sh
aws ec2 authorize-security-group-ingress --group-id "$SG" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
```

Ninguém avisa a Ana, e nada a avisa também. Quando ela pergunta à AWS o que o grupo permite, há uma
regra que ela nunca escreveu:

```
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	22	0.0.0.0/0
ana@laptop:~/shop$ grep -c 22 network.sh
0
```

A porta 22 vinda de `0.0.0.0/0` está lá; o `network.sh` nunca ouviu falar dela. **Essa diferença
entre o que se pretendia e o que existe se chama drift** (deriva), e é o estado normal de qualquer
infraestrutura gerida à mão. Ninguém fez nada de estranho. Uma pessoa resolveu um problema, a nuvem
aceitou a mudança, e o único registro dela é o próprio recurso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo lado a lado. O arquivo network.sh é escrito no dia 1 e nunca muda. O security group real começa igual a ele, ganha a porta 22 à mão no dia 8 e daí em diante difere do arquivo.\"><defs><marker id=\"dr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">network.sh</text><text x=\"70.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">na AWS</text><text x=\"170.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 1</text><text x=\"400.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 8</text><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 30</text><path d=\"M220 70 L570 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M220 170 L570 170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"120\" y=\"48\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><rect x=\"120\" y=\"148\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><rect x=\"570\" y=\"48\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><rect x=\"570\" y=\"148\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><text x=\"620.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">22</text><path d=\"M400 110 L400 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah-amber)\"></path><text x=\"400.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma regra adicionada à mão</text><text x=\"620.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o arquivo e a nuvem discordam</text></svg>", "caption": "Drift: o arquivo fica como foi escrito, e a nuvem guarda o que quer que alguém tenha feito nela.", "same": ["network.sh"]}
```

O drift é pior do que uma anotação que faltou, por três motivos.

**É invisível até alguém comparar.** A rede funciona. A loja vende. A porta aberta aparece numa
auditoria, num incidente, ou quando a rede é reconstruída a partir do script e a pessoa que
precisava do SSH descobre que ele sumiu.

**Ele se acumula.** A próxima mudança é feita sobre a rede como ela está, não como foi escrita, e
então passa a se apoiar num estado que não existe em lugar nenhum além da AWS. Depois de um ano, o
script descreve algo que foi verdade por uma tarde.

**Não pode ser revisado.** Uma mudança num arquivo pode ser lida por um colega antes de acontecer.
Uma mudança digitada num console de nuvem aconteceu antes que alguém pudesse ler, e neste caso
abriu uma porta para a internet inteira.

A cura não é disciplina. Pedir a todo mundo que atualize o script depois de cada mudança manual é
exatamente o arranjo que produziu o drift. A cura é fazer do arquivo o **único caminho** por onde
uma mudança acontece: você edita a descrição, um programa a compara com o que existe, e o programa
faz a mudança. Aí uma diferença entre os dois vira algo que o programa consegue *encontrar*, e a
aula 7 mostra o Terraform encontrando exatamente esta regra.
