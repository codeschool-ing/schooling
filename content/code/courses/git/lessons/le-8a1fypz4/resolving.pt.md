---
title: Resolvendo um conflito, ou desistindo dele
version: 1
---

Resolver são três passos, e só o primeiro exige raciocínio.

**1. Faça o arquivo dizer o que deve.** Abra-o, apague os três marcadores e deixe a versão que você
quer. Muitas vezes ela não é exatamente nenhum dos dois lados. Aqui as duas mudanças estão certas: o
horário de inverno do Bruno e o horário de domingo da Ana. Então a resolução mantém as duas:

```
ana@vm:~/site$ cat index.html
<h1>Padaria Sol</h1>
<p>Bread from half past six; Sundays from seven.</p>
<p><a href="menu.html">See the menu</a></p>
ana@vm:~/site$ git add index.html
ana@vm:~/site$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	modified:   index.html

ana@vm:~/site$ git commit --no-edit
[main 56eb01e] Merge branch 'sunday'
ana@vm:~/site$ git log --oneline --graph -5
*   56eb01e Merge branch 'sunday'
|\  
| * 9677eef Open on Sundays from seven
* | ee92834 Open at half past six in winter
|/  
* 6555c9b Link the menu from the home page
* eadf998 Take rye bread off until the flour arrives
```

**2. Faça `git add` do arquivo.** No meio de um merge, adicionar um arquivo quer dizer *este conflito
está resolvido*. O `git status` muda de tom de acordo: *all conflicts fixed but you are still merging*.

**3. `git commit`.** O Git já escreveu a mensagem, `Merge branch 'sunday'`, e o `--no-edit` a aceitou.
O gráfico mostra um commit de merge comum juntando os dois lados, exatamente a forma que a aula 5
desenhou; a única diferença é que uma pessoa decidiu o que uma linha dele diz.

## O que dá errado no passo 1

- **Deixar um marcador para trás.** O Git não confere o conteúdo por você; um `=======` perdido vai no
  commit como qualquer outro texto. Procure `<<<<<<<` no arquivo antes de adicioná-lo.
- **Escolher um lado sem ler o outro.** Ficar com a *sua* versão é a resolução mais rápida e muitas
  vezes a errada, porque o outro lado também foi a mudança deliberada de alguém. Leia os dois, depois
  decida, e se não conseguir decidir, pergunte a quem está do outro lado: o `git log` da aula 3 diz
  quem é.
- **Consertar mais do que o conflito.** Uma resolução não é lugar para melhorias sem relação. Elas
  ficam enterradas dentro de um commit de merge, onde ninguém que revisa o histórico pensa em olhar.

## Desistindo

Às vezes um conflito é maior do que parecia, ou não é a hora. **O `git merge --abort` põe tudo de volta
como estava antes de o merge começar**:

```
ana@vm:~/site$ git merge lunch
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.
ana@vm:~/site$ git merge --abort
ana@vm:~/site$ git status --short
```

Outro branch em conflito, e desta vez a Ana escolheu não lidar com ele agora. Depois do `--abort` o
status está vazio: sem marcadores, sem merge pela metade, o diretório de trabalho limpo. Nada se
perdeu; o branch continua lá para outro dia.

Vale saber disso antes de precisar, porque um merge pausado é o estado em que iniciantes entram em
pânico. **Sempre há um caminho de volta para o momento antes de você digitar `git merge`**, e o Git o
imprime no `git status` enquanto o merge estiver aberto.
