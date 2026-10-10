---
title: Um operador que copia de um cofre
version: 1
---

**A aula 9 terminou com um token que o Vault entrega a um pod que prova quem é.** Mas as aplicações
raramente falam com o Vault, e a maioria lê segredos do jeito comum do Kubernetes: de um Secret,
montado como arquivo ou posto numa variável de ambiente. O **External Secrets Operator** junta as
duas coisas. Ele roda no cluster, entra num cofre de segredos, lê as entradas que você nomeia e as
escreve em Secrets comuns, e continua lendo periodicamente para os Secrets acompanharem o cofre.

Ele acrescenta dois tipos de objeto, e só o segundo é sobre um segredo específico:

- um **SecretStore** diz onde está um cofre e como entrar nele: o Vault neste endereço com este role,
  o AWS Secrets Manager nesta região com esta identidade. Um `ClusterSecretStore` é o mesmo para todo
  namespace;
- um **ExternalSecret** diz quais entradas ler de um cofre, e em qual Secret escrevê-las.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Como o External Secrets Operator funciona. O Git guarda um SecretStore e um ExternalSecret, e o Flux os aplica no cluster. O operador lê o ExternalSecret, entra no cofre que o SecretStore nomeia, lê a entrada e escreve um Secret comum, que o pod monta. O operador repete a leitura periodicamente, então o Secret acompanha o cofre. O valor nunca passa pelo Git.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"300\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"40\" width=\"150\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"95.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">SecretStore, ExternalSecret</text><line x1=\"170\" y1=\"75\" x2=\"220.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"228,75 220.0,70.5 220.0,79.5\" fill=\"var(--paper-dim)\"/><text x=\"199\" y=\"66\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">Flux</text><rect x=\"230\" y=\"20\" width=\"470\" height=\"260\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-dasharray=\"4 4\"/><text x=\"245\" y=\"40\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">o cluster</text><rect x=\"250\" y=\"50\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"335.0\" y=\"75.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">External Secrets</text><text x=\"335.0\" y=\"93.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Operator</text><rect x=\"510\" y=\"50\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"595.0\" y=\"75.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cofre</text><text x=\"595.0\" y=\"93.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Vault, ou um serviço de nuvem</text><line x1=\"420\" y1=\"72\" x2=\"500.0\" y2=\"72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"508,72 500.0,67.5 500.0,76.5\" fill=\"var(--paper-dim)\"/><text x=\"464\" y=\"64\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">entra, lê</text><line x1=\"508\" y1=\"92\" x2=\"430.0\" y2=\"92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"422,92 430.0,96.5 430.0,87.5\" fill=\"var(--paper-dim)\"/><text x=\"464\" y=\"108\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">o valor</text><rect x=\"250\" y=\"180\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"335.0\" y=\"205.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Secret</text><text x=\"335.0\" y=\"223.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">um comum</text><line x1=\"335\" y1=\"110\" x2=\"335.0\" y2=\"170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"335,178 339.5,170.0 330.5,170.0\" fill=\"var(--paper-dim)\"/><text x=\"345\" y=\"150\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">escreve, e de novo</text><text x=\"345\" y=\"164\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">a cada atualização</text><rect x=\"510\" y=\"180\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"595.0\" y=\"205.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pod</text><text x=\"595.0\" y=\"223.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">monta o Secret</text><line x1=\"420\" y1=\"210\" x2=\"500.0\" y2=\"210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"508,210 500.0,205.5 500.0,214.5\" fill=\"var(--paper-dim)\"/></svg>", "caption": "O Git guarda qual segredo e de onde; o cofre guarda o valor. O operador é a única coisa que lê o cofre, e ele escreve um Secret comum que o pod já sabe usar.", "same": ["Git", "Flux", "SecretStore, ExternalSecret", "External Secrets", "Operator", "Secret", "pod"]}
```

**O que vai para o Git é o ExternalSecret, que não guarda segredo nenhum.** Ele diz "o token da
produção é o campo `token` de `bulletin/production`", e o cofre diz o que isso é hoje. Quem revisa
lê qual segredo uma carga recebe e de onde; o valor nunca aparece num pull request, num diff ou num
clone. E como o operador continua lendo, **mudar o valor no cofre muda o cluster sem um commit**,
que é exatamente o que a aula 11 precisa para a rotação, e exatamente o que um purista de GitOps vai
contestar: o conteúdo do Secret passa a ser estado que o Git não descreve. A resposta é que o Git
descreve *qual* segredo e *quem pode lê-lo*, e o cofre descreve o valor e mantém o próprio histórico
e log de auditoria. A aula 12 lê os dois.

O operador funciona igual com qualquer cofre para o qual tenha um provedor: o Vault, os serviços de
segredos das três grandes nuvens e algumas dezenas de outros. Esta aula o roda contra o Vault da
aula 9, e depois mostra o que muda, que é muito pouco, quando o cofre é o de uma nuvem.
