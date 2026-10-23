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

@@FENCE 1@@

A primeira linha é o que uma compilação em meados de 2024 teria produzido, a segunda o que a
compilação desta aula produz. E as faixas do próprio linkbox no início de agosto falham de vez,
porque ainda não existia gunicorn 26.2: o resolvedor diz qual requisito não pôde ser atendido. **Uma
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

@@FIGURE cooloff@@

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
