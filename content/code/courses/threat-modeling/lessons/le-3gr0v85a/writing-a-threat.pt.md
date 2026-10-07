---
title: Escrevendo uma ameaça
version: 1
---

Metade das ameaças escritas numa primeira sessão não são ameaças. "Injeção de SQL." "O banco." "Sem
MFA." Cada uma nomeia um assunto, e um assunto não dá para riscar da lista: ninguém sabe dizer se
"o banco" foi tratado. **Uma ameaça se escreve como alguém fazendo algo com alguma coisa, com um
resultado**, e cada parte dessa frase está ali porque um passo seguinte precisa dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l03-threat-anatomy\" aria-label=\"Uma ameaça escrita em quatro partes, usando a T07. Quem: um paciente logado. Faz o quê: muda o número do exame no endereço. Em quê: o PDF do exame de outro paciente. Com que resultado: baixa o arquivo, o que divulga dado de saúde. Embaixo, a letra I do STRIDE e o elemento, o fluxo 2.\"><defs><marker id=\"l03-threat-anatomy-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">quem</text><rect x=\"20.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um paciente</text><text x=\"100.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">logado</text><path d=\"M180.0 68.0 L192.0 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-threat-anatomy-tm-ah-paper-dim)\"></path><text x=\"272.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">faz o quê</text><rect x=\"192.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">muda o número do</text><text x=\"272.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exame no endereço</text><path d=\"M352.0 68.0 L364.0 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-threat-anatomy-tm-ah-paper-dim)\"></path><text x=\"444.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">em quê</text><rect x=\"364.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"444.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o PDF do exame</text><text x=\"444.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de outro paciente</text><path d=\"M524.0 68.0 L536.0 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-threat-anatomy-tm-ah-paper-dim)\"></path><text x=\"616.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">com que resultado</text><rect x=\"536.0\" y=\"38.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"616.0\" y=\"61.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">baixa: dado de saúde</text><text x=\"616.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">divulgado</text><rect x=\"20.0\" y=\"125.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">STRIDE: I</text><rect x=\"192.0\" y=\"125.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"272.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">elemento: fluxo 2</text><text x=\"370.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">registrada como T07</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Se faltar uma parte, ninguém consegue dizer se a ameaça foi tratada.</text></svg>", "caption": "Uma ameaça nomeia alguém fazendo algo com alguma coisa, e o que acontece então. A letra e o elemento dizem onde ela mora.", "same": ["STRIDE: I"]}
```

| parte | por que é necessária | quando falta, fica assim |
|---|---|---|
| **quem** | decide quão provável é, e quais controles valem: um paciente, um desconhecido, alguém da equipe | "um atacante consegue ler exames" (que atacante? logado ou não?) |
| **faz o quê** | a ação, no nível do projeto | "via IDOR" (um nome de técnica, não uma ação) |
| **em quê** | o ativo, que decide o impacto | "acessar dados" (de quem? quais dados?) |
| **com que resultado** | a consequência com que uma pessoa se importaria | "um problema de segurança" |

Duas regras mantêm as frases honestas:

**Nomeie o projeto, não o bug.** "A rota de download não confere se o exame pertence ao paciente
logado" é uma afirmação sobre uma verificação que falta, que um projeto consegue corrigir. "Há um
IDOR em `/exams/{id}`" é um achado sobre código que pode ainda nem existir. Antes de o código ser
escrito, só a primeira pode ser verdade.

**Uma ameaça por frase.** "Atacantes poderiam falsificar, adulterar e ler o webhook" são três
ameaças com três correções diferentes. Escritas como uma, a primeira correção a risca da lista e as
outras duas somem junto.

### Reescrevendo os primeiros rascunhos

As notas da primeira sessão, e no que cada uma se transformou:

| primeiro rascunho | reescrita | |
|---|---|---|
| "segurança do webhook" | qualquer um que descubra o endereço do webhook consegue marcar um agendamento como pago | T01 |
| "sem MFA" | a senha de uma recepcionista roubada por phishing, sem segundo fator para impedir o uso | T03 |
| "IDOR" | um paciente muda o número do exame no endereço e baixa o PDF de outra pessoa | T07 |
| "DoS" | uploads não têm limite de tamanho; arquivos grandes enchem o armazenamento | T10 |
| "o banco" | (nada: era um assunto, e as ameaças específicas eram T05, T09 e T13) | |

A última linha é a útil. "O banco" parecia um achado, e quando a equipe tentou escrevê-lo como
frase ele se revelou três ameaças diferentes, de três pessoas diferentes, cada uma com a sua
correção. Um assunto que não vira frase é sinal de que o trabalho ainda não terminou.
