---
title: O que conta como evidência
version: 1
---

A opinião de um auditor se apoia em evidência, e evidência tem uma qualidade que pode ser discutida.
As normas de evidência de auditoria variam nas palavras e concordam na substância: a evidência
precisa ser **relevante** para a afirmação, **confiável** e **suficiente** em quantidade, e precisa
cobrir o período auditado.

### Como ela é obtida

Há quatro jeitos de obtê-la, e eles não são iguais:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l14-evidence\" aria-label=\"Quatro jeitos de obter evidência, da mais fraca à mais forte. Indagação: perguntar a alguém, que diz que a equipe usa segundo fator. Observação: ver alguém entrar com um. Inspeção: ler a configuração do console, ou um log de 40 logins. Reexecução: o auditor tenta entrar sem o segundo fator e é recusado.\"><rect x=\"40.0\" y=\"150.0\" width=\"150.0\" height=\"60.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">indagação</text><text x=\"115.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">“sim, todo mundo usa”</text><rect x=\"210.0\" y=\"115.0\" width=\"150.0\" height=\"95.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">observação</text><text x=\"285.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ver um login</text><rect x=\"380.0\" y=\"80.0\" width=\"150.0\" height=\"130.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">inspeção</text><text x=\"455.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a configuração, um log de 40</text><rect x=\"550.0\" y=\"45.0\" width=\"150.0\" height=\"165.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reexecução</text><text x=\"625.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o auditor tenta, e é recusado</text></svg>", "caption": "Indagação sozinha nunca basta numa auditoria: o que alguém diz precisa ser sustentado por algo que o auditor lê ou faz."}
```

| método | o que o auditor faz | para o C1, o segundo fator |
|---|---|---|
| **indagação** | pergunta a alguém | o bruno diz que toda conta da equipe usa um |
| **observação** | vê acontecer | uma recepcionista entra enquanto o auditor olha |
| **inspeção** | lê um registro ou uma configuração | as configurações de autenticação do console, e um log de logins |
| **reexecução** | faz de novo, de forma independente | o auditor tenta um login da equipe sem o segundo fator e é recusado |

A indagação é onde toda auditoria começa e onde nenhuma pode terminar. O que alguém diz é a
afirmação; os outros três são a evidência dela.

### Desenho e funcionamento

Um controle pode ser conferido de dois jeitos. **Desenho**: ele funcionaria, do jeito que foi
construído? Uma reexecução responde. **Funcionamento**: ele funcionou, toda vez, ao longo do período?
Isso pede uma população e uma amostra. Se o console registrou 1.240 logins da equipe em outubro, o
auditor escolhe uma amostra, digamos 25, e confere que cada um passou por um segundo fator. Uma
exceção em 25 é um achado sobre funcionamento mesmo quando o desenho é perfeito.

É a mesma distinção entre um SOC 2 Tipo I e um Tipo II da aula 13, vista da cadeira do auditor.

### O que torna uma evidência confiável

Três perguntas que um auditor cuidadoso faz a cada item:

- **Quem a produziu?** Um log que o sistema escreveu é melhor que uma planilha que uma pessoa
  digitou. Um registro mantido por alguém independente do controle é melhor que um mantido pela
  pessoa que ele confere.
- **Quando ela foi produzida?** Evidência feita na hora do evento é melhor que evidência montada
  depois. Um print tirado na semana antes da auditoria diz o que era verdade naquela semana.
- **Ela poderia ter sido mudada?** Um registro que pode ser editado sem deixar rastro é mais fraco que
  um em que toda mudança deixa marca.

O modelo de ameaças vai bem nas duas últimas, porque mora no git. A próxima seção lê esse histórico
como um auditor leria, incluindo as partes que vão mal.
