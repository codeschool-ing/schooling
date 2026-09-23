---
title: Ignorar não é deixar de acompanhar, e um segredo fica no histórico
version: 1
---

Dois erros com o `.gitignore` são comuns o bastante para ter uma seção própria, e o segundo sai caro.

## Pondo no .gitignore um arquivo que já foi para commit

O `settings.local` foi para um commit, e depois entrou no `.gitignore`. Alguém o edita:

```
ana@vm:~/site$ git status --short
 M settings.local
ana@vm:~/site$ git rm --cached settings.local
rm 'settings.local'
ana@vm:~/site$ git status --short
D  settings.local
ana@vm:~/site$ git commit -qm "Stop tracking local settings"
ana@vm:~/site$ git status --short
```

**O `.gitignore` só vale para arquivos que o Git ainda não acompanha.** O arquivo estava no histórico,
então o Git continuou acompanhando, e a edição aparece como ` M` como qualquer outra. Para parar, **o
`git rm --cached` o tira da área de preparo e o deixa no seu disco.** O próximo commit registra a saída
do arquivo do projeto, e dali em diante a regra de ignorar vale: o último `git status` está vazio.

Todo mundo que puxar esse commit perde o arquivo do diretório de trabalho, porque para eles é uma
remoção comum. Para um arquivo de configurações locais isso costuma ser o que se quer, mas diga isso na
mensagem do commit.

## Um segredo que foi para um commit sem querer

Uma chave de pagamento foi para um commit, e o commit seguinte a removeu:

```
ana@vm:~/site$ git log --oneline -2
f463511 Remove the payment key
dd37a3f Configure payments
ana@vm:~/site$ ls .env && git status --short
.env
ana@vm:~/site$ git show HEAD~1:.env
PAYMENT_KEY=sk_live_example_not_a_real_key
```

O arquivo está no disco e ignorado agora, e o diretório de trabalho está limpo. E o
`git show HEAD~1:.env` imprime a chave, porque **apagar um arquivo não muda o commit que o
acrescentou.** Esse commit está no histórico, em todo clone, e na cópia compartilhada se foi enviado. A
aula 1 disse que o histórico não pode ser alterado sem que isso apareça; aqui essa garantia joga contra
você.

Então a regra, em ordem:

1. **Trate o segredo como público desde o momento em que foi para o commit.** Revogue e crie outro: uma
   senha nova, uma chave nova. É o único passo que de fato resolve alguma coisa.
2. Depois, se os commits nunca foram enviados, reescreva-os com as ferramentas da aula 4 antes que
   sejam.
3. Se foram enviados, existem ferramentas para reescrever o histórico inteiro sem o arquivo, sendo o
   `git filter-repo` a de costume. Todo clone então tem de ser substituído, o que é decisão da equipe, e
   isso ainda não desfaz cópias que alguém já fez.

GitHub e GitLab examinam os commits enviados atrás de padrões que parecem chaves e avisam, o que pega
alguns desses casos em minutos. Não muda o passo 1.

**A prevenção é a lista de ignorados.** O `.env` e arquivos parecidos entram no `.gitignore` antes de
alguém escrever um segredo neles.
