---
title: Acessibilidade, pelo teclado e lendo a página
version: 1
---

Acessibilidade costuma ser tratada como uma funcionalidade para um grupo pequeno de usuários,
acrescentada quando sobra tempo. Os números dizem outra coisa: pessoas que não conseguem usar um
mouse, que não enxergam a tela, que a enxergam ampliada ou que não distinguem vermelho de verde são
uma parte de todo público, e o público de um teatro inclui todas elas. O R9 faz disso um requisito
do boxoffice: toda página utilizável só com o teclado e com um leitor de tela, segundo a **WCAG 2.2
nível AA**, as Diretrizes de Acessibilidade para Conteúdo Web do W3C, que são aquilo a que a
maioria das leis e dos contratos se refere.

Duas das verificações mais baratas não precisam de ferramenta nenhuma, e acham boa parte dos
problemas.

## Um passeio pelo teclado

Ponha o mouse fora de alcance. Abra `http://127.0.0.1:8000`, clique uma vez na barra de endereço
para que a página ainda não esteja em foco, e aperte **Tab**. Cada toque leva o foco à próxima coisa
que você pode usar; **Shift+Tab** volta, **Enter** segue um link ou aperta um botão, **Espaço** marca
uma caixa e as setas andam dentro de uma lista. No Mac, o Safari pula os links ao tabular até que
"Pressionar Tab para destacar cada item em uma página web" seja ligado nos ajustes dele; Chrome e
Firefox não precisam disso.

Na página Shows o foco deveria ir aos três links **Book** da tabela, depois aos três links do pé da
página. Siga o link Book de Hamlet com Enter e, na página de reserva, tabule pelo campo de e-mail,
pela lista de espetáculos, pelo campo de ingressos, pela caixa de estudante e pelo botão Book.
Faça uma reserva inteira digitando e aperte o botão sem encostar no mouse.

O que você observa, a cada passo:

- Dá para chegar lá? Algo que se clica mas não se alcança com Tab é inutilizável para quem não usa
  mouse.
- Dá para ver onde você está? O elemento em foco precisa de um contorno visível. Os navegadores
  desenham um por padrão, e muitas páginas o tiram por estética.
- A ordem faz sentido? O foco deveria seguir a página na ordem em que ela se lê, de cima para baixo,
  e não pular de um lado para outro.
- Dá para sair? Um componente que toma o foco e nunca o devolve é uma armadilha de teclado, e
  encerra a sessão de quem usa o teclado.

As páginas do boxoffice são HTML simples, e o passeio vai até o fim sem tropeço: todo controle é
alcançável, em ordem, com o contorno do navegador aparecendo. Isso também vale anotar. Uma
verificação que passou é um resultado, e a próxima versão pode desfazê-lo.

## O campo sem rótulo

Olhe a página de reserva do jeito que um leitor de tela olha, ou seja, pela marcação. No navegador,
clique com o botão direito no campo de ingressos e escolha **Inspecionar**; pelo terminal:

```
ana@laptop:~$ curl -s http://127.0.0.1:8000/book | grep -E '<input|<select'
<p><label for="email">E-mail</label> <input id="email" name="email"></p>
<p><label for="show">Show</label> <select id="show" name="show"><option value="S1" selected>The Seagull</option><option value="S2">Hamlet</option><option value="S3">The Little Prince</option></select></p>
<p><input name="quantity" placeholder="Tickets (1 to 6)"></p>
<p><label><input type="checkbox" name="student"> Student (half price)</label></p>
```

Três dos quatro controles têm um rótulo ligado a eles. `E-mail` e `Show` usam `<label for="…">`, que
aponta para o `id` do campo; a caixa de estudante fica dentro do seu rótulo, o que também funciona.
O campo de ingressos não tem nenhum dos dois. Ele tem um **placeholder**, o texto cinza "Tickets (1
to 6)" que aparece dentro da caixa vazia, e **mais nada**. Esse é o defeito que esta seção acha.

Um placeholder não é um rótulo, por três motivos que um testador confere à mão. Ele **some assim que
você digita**, então quem desvia o olhar e volta vê um "2" sem ideia do que aquilo conta. Um leitor
de tela pode anunciá-lo ou não, conforme o leitor e o navegador, então alguns usuários ouvem só
"editar texto". E clicar nas palavras não faz nada, enquanto clicar em "E-mail" põe o cursor no
campo de e-mail, o que importa para qualquer pessoa cujas mãos tornam alvos pequenos difíceis. A
correção é uma linha: um `<label for="quantity">Tickets</label>` e um `id` no campo.

## O que as ferramentas veem, e o que deixam passar

O **axe** é um verificador automático muito usado, com uma extensão gratuita para o navegador e uma
biblioteca embutida em muitos frameworks de teste, e WAVE e Lighthouse são outros dois que você vai
encontrar. Rode um em toda página: ele acha texto alternativo faltando, contraste fraco e estrutura
quebrada em segundos.

Depois, leia o resultado sabendo o que ele é. Quando este curso rodou o axe-core 4.13 na página de
reserva, com as regras da WCAG 2.2 AA, ele não relatou **violação nenhuma**. Ele conta o placeholder
como o nome do campo, o que é uma leitura defensável das regras, e aprova o campo que esta seção
acabou de reprovar. **Um relatório automático limpo não é uma aprovação**: as ferramentas conferem o
que dá para decidir pela marcação, e se uma pessoa consegue usar a página não é uma dessas coisas.

Essa última verificação pertence às pessoas que usam **leitores de tela** todo dia, e aos testadores
que aprendem a usar um. O NVDA é gratuito no Windows, o VoiceOver vem no macOS e no iOS, o TalkBack
no Android, e o JAWS é o comercial de longa data. Usar um bem exige prática, e é por isso que esta
aula não pede isso a você; o `non-functional-testing` ensina a auditoria direito, critérios da WCAG
e tecnologia assistiva juntos. O que esta aula pede é o passeio pelo teclado em toda página que você
testar e uma olhada no rótulo de todo campo de formulário, porque foram esses dois que acharam o
rótulo faltando quando a ferramenta não achou.
