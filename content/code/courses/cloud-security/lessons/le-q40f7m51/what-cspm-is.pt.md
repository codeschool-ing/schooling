---
title: Postura é a configuração, lida de novo e de novo
version: 1
---

**A postura de segurança de uma conta de nuvem é o estado da configuração dela neste momento: quais
buckets estão públicos, quais portas dão para a internet, quais usuários entram com um fator só. O
gerenciamento de postura de segurança na nuvem, o CSPM, é um programa que lê esse estado pela API,
compara com uma lista de regras e relata cada ponto em que os dois discordam. Depois lê de novo
amanhã.**

A imagem errada é a de uma auditoria: um consultor passa duas semanas com a conta, escreve um
relatório, e agora se sabe que a conta está bem. Ela estava bem no dia em que o relatório foi
escrito. A aula 1 mostrou como uma mudança é curta na nuvem — uma requisição tornou um bucket público
e não imprimiu nada —, então uma configuração conferida em março diz muito pouco sobre outubro.
**Postura é uma leitura, não um certificado**, e a leitura envelhece na velocidade da API.

## O que ele lê, e o que não lê

A aula 1 já deixou o ponto em que esta aula se apoia: na nuvem, **inventário é uma consulta**. Todo
bucket, todo security group e todo usuário está a um `describe` ou `list` de distância. Uma
ferramenta de CSPM é essa consulta rodada num horário fixo, sobre todo serviço e toda região, com uma
regra ao lado de cada resposta:

| ela pergunta | a regra | aula |
|---|---|---|
| uma política de bucket permite `"Principal": "*"`? | armazenamento não é público a menos que alguém tenha decidido | 9 |
| um bucket tem criptografia padrão? | dado em repouso é cifrado | 11 |
| um security group permite a porta 22 a partir de `0.0.0.0/0`? | administração não fica aberta para o mundo | 8 |
| um usuário entra sem segundo fator? | pessoas usam MFA | 6 |
| existe uma chave de acesso com dois anos de idade? | chaves são trocadas | 7 |

Quase toda aula deste curso termina numa configuração que deveria estar de um jeito e pode escorregar
para o outro. **Uma ferramenta de CSPM são essas aulas transformadas em regras que rodam sem você.**

Três vizinhos fazem trabalhos diferentes, e confundi-los é como uma equipe acaba acreditando que está
coberta:

- **um scanner de vulnerabilidades** lê software: uma biblioteca velha, um kernel sem atualização. A
  aula 13 roda um sobre as dependências de uma função. Ele não diz nada sobre quem pode ler um bucket;
- **a detecção de ameaças** lê eventos: uma chave usada de um país novo, uma rajada de `ListBuckets`
  às três da manhã. O GuardDuty da AWS, os alertas de ameaça do Microsoft Defender e o Event Threat
  Detection do Google são isso. Eles reagem ao que alguém fez, e a aula 15 trata dos registros que
  eles leem;
- **o CSPM** lê configuração. Ele acha a porta aberta antes de alguém passar por ela, e não consegue
  dizer se alguém já passou.

## As regras vêm de algum lugar

Uma lista de regras é opinião até alguém publicá-la. As que a maioria das ferramentas usa como ponto
de partida são os **CIS Benchmarks** para AWS, Azure e Google Cloud, do mesmo Center for Internet
Security que publica um para cada sistema operacional, e o conjunto de boas práticas de cada
provedor. Nenhum dos dois conhece a clínica. O site público tem de ser um bucket público, e uma regra
que o aponta toda manhã é uma regra que as pessoas aprendem a ignorar. A seção depois do scanner trata
disso: um achado não é uma correção, e uma exceção precisa de um motivo e de uma data de fim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-loop\" aria-label=\"O ciclo de postura. O scanner lê a configuração pela API, compara cada resposta com as regras e escreve achados. Cada achado vai para um dono, que o corrige ou o aceita com um motivo e uma data de fim. A próxima varredura lê a configuração de novo. O desvio, uma mudança feita à mão depois da varredura, entra na configuração por fora do ciclo, e só a próxima leitura o vê.\"><defs><marker id=\"l16-loop-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-loop-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l16-loop-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"110.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">configuração</text><text x=\"110.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o que a API responde</text><rect x=\"220.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"290.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">regras</text><text x=\"290.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">CIS, provedor, suas</text><rect x=\"400.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"470.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">achados</text><text x=\"470.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">regra, recurso, detalhe</text><rect x=\"560.0\" y=\"50.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"625.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">corrigir</text><text x=\"625.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">pelo dono</text><rect x=\"560.0\" y=\"170.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"625.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aceitar</text><text x=\"625.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">motivo e data de fim</text><path d=\"M182.0 140.0 L218.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><text x=\"200.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ler</text><path d=\"M362.0 140.0 L398.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><path d=\"M542.0 128.0 L558.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><path d=\"M542.0 152.0 L558.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-paper-dim)\"></path><path d=\"M625 232 L625 270 L110 270 L110 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-loop-af-ah-phosphor)\"></path><path d=\"M690 80 L705 80 L705 270 L625 270\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"370.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a próxima varredura lê tudo de novo</text><path d=\"M110.0 34.0 L110.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l16-loop-af-ah-amber)\"></path><text x=\"124.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">desvio: uma mudança à mão depois da varredura</text></svg>", "caption": "Um achado não é o fim do ciclo: a correção, ou a exceção com data, é conferida pela próxima leitura, e também toda mudança feita à mão no meio do caminho."}
```

As próximas duas seções montam o ciclo no seu próprio computador: uma conta com quatro falhas dentro,
e um programa de cinquenta e seis linhas que as encontra.
