---
title: A linha, e os dois tipos de prova de cada lado dela
version: 1
---

**O curso `cloud` desenhou o modelo de responsabilidade compartilhada como uma linha atravessando uma
pilha: abaixo dela o provedor faz o trabalho, acima dela você faz. Para um engenheiro de segurança a
linha tem um segundo sentido. Ela também separa dois tipos de prova, e você vai passar a vida
profissional reunindo a do seu lado.** A aula 1 daquele curso é o desenho; esta aula é o que você faz
com ele.

A imagem errada é a de que a linha divide a *culpa*: se algo quebra abaixo dela, o provedor paga, e
se quebra acima, você paga. Um contrato diz algo assim, e um relatório de incidente nunca diz. Quando
prontuários de pacientes vazam, as pessoas que estão neles não perguntam qual camada de uma pilha
falhou. A clínica responde por elas perante a LGPD seja quem for que operava a camada com defeito, e
as multas e a reputação são dela. **A responsabilidade é dividida; as consequências não.**

## Abaixo da linha, você lê um relatório

Nada abaixo da linha pode ser inspecionado por você. Ninguém vai lhe mostrar o hipervisor, deixar
você andar pelo prédio ou ler o registro de acesso dos próprios engenheiros do provedor. O que você
recebe no lugar é uma **atestação de terceiros**: um auditor contratado pelo provedor examinou esses
controles contra uma norma publicada e escreveu o que encontrou. Duas seções adiante, esta aula diz o
que um desses relatórios contém e o que ele não consegue dizer.

É uma prova mais fraca que um teste, e é a única disponível. Também é a mesma para todo cliente: o
provedor roda um hipervisor para todos eles, e um relatório o cobre.

## Acima da linha, você pergunta à API

Tudo acima da linha é uma configuração, e toda configuração pode ser lida de volta. Se um bucket é
criptografado, se ele pode ficar público, quem tem uma chave que ainda funciona, quais portas de rede
estão abertas para a internet: cada uma está a uma requisição de distância, e a resposta é específica
da **sua** conta, **agora**. É uma prova do tipo forte, e também é um dever. Ninguém mais vai fazer
essas perguntas sobre a sua conta, porque ninguém mais pode.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l02-evidence\" aria-label=\"A linha da responsabilidade compartilhada, com a prova disponível de cada lado. Acima da linha, as configurações do cliente: quem tem uma chave que funciona, se um bucket é criptografado ou pode ficar público, quais portas estão abertas. A prova delas é uma requisição à API, e a resposta é sobre a sua conta, agora. Abaixo da linha, o trabalho do provedor: o hipervisor, os prédios, a rede física, o acesso da própria equipe dele. A prova disso é o relatório de um auditor, que fala de todos os clientes, num período passado.\"><defs><marker id=\"l02-evidence-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l02-evidence-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"30.0\" width=\"330.0\" height=\"125.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">seu: configurações na sua conta</text><text x=\"56.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem tem uma chave que ainda funciona</text><text x=\"56.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o bucket é criptografado, pode ficar público</text><text x=\"56.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quais portas estão abertas para a internet</text><path d=\"M18.0 172.0 L372.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"195.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a linha</text><rect x=\"30.0\" y=\"200.0\" width=\"330.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">do provedor: o trabalho dele</text><text x=\"56.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hipervisor, prédios, rede física</text><text x=\"56.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o acesso dos próprios engenheiros</text><text x=\"56.0\" y=\"292.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o mesmo para todo cliente</text><path d=\"M364.0 92.0 L436.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-evidence-af-ah-phosphor)\"></path><rect x=\"440.0\" y=\"50.0\" width=\"250.0\" height=\"85.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">perguntar à API</text><text x=\"565.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sobre a sua conta</text><text x=\"565.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agora</text><path d=\"M364.0 255.0 L436.0 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-evidence-af-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"212.0\" width=\"250.0\" height=\"85.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">ler o relatório de um auditor</text><text x=\"565.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sobre todos os clientes</text><text x=\"565.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">num período passado</text></svg>", "caption": "A linha divide a prova além do trabalho. Só a prova acima dela é sobre a sua conta, e só você pode reuni-la."}
```

## As camadas que nunca mudam de lado

Duas camadas ficam acima da linha em todo modelo, e são a razão de este curso existir: **os dados e
quem consegue alcançá-los**. Um provedor pode criptografar seus discos, aplicar correções nos próprios
servidores e manter o prédio trancado, e os prontuários da clínica vão continuar exatamente tão
privados quanto as configurações da própria clínica permitem. As aulas 6 a 11 tratam dessas duas
camadas, um controle de cada vez.
