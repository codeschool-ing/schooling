---
title: Uma data na compilação, e uma atualização decidida
version: 1
---

O `uv pip compile` sem data responde a uma pergunta sobre o momento em que roda: para o que estas
faixas resolvem no PyPI agora? Rode na semana que vem e a resposta pode mudar, porque alguém publicou
algo. **`--exclude-newer 2026-10-16` troca a pergunta por uma de resposta fixa**: para o que estas
faixas resolviam usando só arquivos enviados antes dessa data? A data fica escrita no cabeçalho do
lock, então qualquer um pode rodar de novo o mesmo comando e obter o mesmo arquivo.

### As mesmas faixas em duas datas

Um `flask` puro, sem faixa nenhuma, resolvido em duas datas:

```
ana@vm:~/linkbox$ for d in 2024-06-01 2026-10-16; do echo "$d: $(echo flask | uv pip compile - --exclude-newer $d --no-header 2>/dev/null | grep -E "^(flask|werkzeug)==" | tr "\n" " ")"; done
2024-06-01: flask==3.0.3 werkzeug==3.0.3 
2026-10-16: flask==3.1.3 werkzeug==3.1.9 
ana@vm:~/linkbox$ uv pip compile requirements.in --exclude-newer 2026-08-01 --no-header 2>&1 | tail -n 1
hint: `gunicorn` was filtered by `exclude-newer` to only include packages uploaded before 2026-08-02T03:00:00Z. The latest version satisfying the requirement is v26.2.0, published at 2026-08-24T15:05:57.67Z. Consider using `exclude-newer-package` to override the cutoff for this package.
```

A primeira linha é o que uma compilação em meados de 2024 teria produzido, a segunda o que a
compilação desta aula produz. E as faixas do próprio linkbox no início de agosto falham de vez,
porque ainda não existia gunicorn 26.2. A última linha do erro do uv, a dica, diz isso e nomeia o
envio que teria atendido à faixa. **Uma
data torna uma resolução reproduzível, e também a torna explícita**: mover a data é uma mudança num
arquivo, revisada como qualquer outra, e o diff do lock mostra exatamente o que movê-la fez.

### A data como período de quarentena

A data faz um segundo trabalho, e para segurança é o mais importante. Releases maliciosos costumam ser
descobertos e removidos em poucos dias: os incidentes que a aula 12 colocou na cadeia de suprimentos,
do event-stream aos pacotes publicados a partir de contas roubadas de mantenedores, ficaram no ar por
horas ou dias até alguém notar. **Uma compilação que recusa tudo o que foi enviado nos últimos dias
nunca pega um release dessa janela**, diga o número de versão o que disser.

Por isso a data no comando desta aula é uma semana antes da gravação, de propósito. A regra que um
time pode adotar é simples de dizer: a data avança quando alguém escolhe atualizar, e nunca chega mais
perto de hoje do que um número fixo de dias. O uv também aceita a quarentena por configuração em vez
da linha de comando, e a aula 18 configura a mesma ideia, uma idade mínima de release, para os bots
que propõem atualizações.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 175\" role=\"img\" data-fig=\"sp-l15-cooloff\" aria-label=\"Uma linha do tempo. Um release ruim é publicado, descoberto e removido em poucos dias. Uma compilação com uma data de exclude-newer uma semana antes de hoje só vê o que foi enviado antes dessa data, então um release dentro da janela nunca é escolhido. Avançar a data é uma mudança deliberada no lock.\"><defs><marker id=\"sp-l15-cooloff-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l15-cooloff-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 122 L700 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-cooloff-ah-paper-dim)\"></path><rect x=\"20\" y=\"70\" width=\"430\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"235\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que a compilação enxerga</text><rect x=\"450\" y=\"70\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">ainda não enxergado</text><line x1=\"450\" y1=\"40\" x2=\"450\" y2=\"66\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"450\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">--exclude-newer</text><line x1=\"690\" y1=\"40\" x2=\"690\" y2=\"66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"690\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hoje</text><text x=\"570\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma semana</text><path d=\"M520 140 L520 112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-cooloff-ah-amber)\"></path><text x=\"515\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">release ruim publicado</text><text x=\"525\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">→ descoberto e removido</text></svg>", "caption": "A compilação só olha o que foi enviado antes da data, então um release precisa sobreviver a uma semana do escrutínio de outras pessoas antes de chegar ao lock."}
```

O custo é real e vale dizer: uma correção publicada ontem para um aviso publicado ontem também fica
retida. Esse é o caso para uma exceção, feita por uma pessoa, para um pacote; o gate da aula 7 já tem
lugar para decisões assim, com dono e data.

### Atualizando o gunicorn de 22 para 26

A compilação levou o gunicorn de 22.0.0 para 26.2.0 porque o `requirements.in` pede `>=26.2,<27`.
Essa faixa é uma decisão, e merece as perguntas que toda atualização recebe:

1. **O que mudou?** Quatro versões major, de 23 a 26. As notas de cada major estão no changelog do
   gunicorn em gunicorn.org/news, com link no PyPI, e as perguntas a levar até elas são estreitas:
   alguma configuração removida aparece no jeito como o linkbox inicia o gunicorn, e algum padrão de
   que ele depende muda? O linkbox passa uma configuração, `--bind`, no entry point do Dockerfile. O
   changelog não foi reproduzido aqui; lê-lo é o passo, e é seu para a versão que você encontrar.
2. **O que ela traz ou tira?** Nada entra, o `packaging` sai, como a seção anterior mostrou.
3. **Os testes passam?** Passaram, contra o lock novo, na seção anterior.
4. **O serviço ainda sobe do jeito que roda em produção?** Isso é a imagem construída na próxima seção
   e rodada pelo pipeline, e a varredura noturna de staging da aula 4 a roda como servidor.

**Uma atualização de quatro majors não é arriscada porque o número é grande; ela é arriscada quando
ninguém leu o que mudou.** Lida, testada e rodada, ela é o movimento comum, e ficar no 22 só teria
deixado o próximo salto mais longo.
