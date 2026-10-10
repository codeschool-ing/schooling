import sys; sys.path.insert(0, '/tmp/lab/bin')
from exlib import *
X = []

# ---- what-arrives -----------------------------------------------------------

X.append(quiz('ex-vqd02bbq', 'what-arrives', 'easy',
  ("`curl -s http://localhost:3000/ | grep -c '<h2>'` prints `0`, and the same question to `/ssr` finds eight. Why?",
   "`curl -s http://localhost:3000/ | grep -c '<h2>'` imprime `0`, e a mesma pergunta a `/ssr` acha oito. Por quê?"),
  [("curl runs no script, and only `/ssr` has the products in its HTML", "O curl não roda script, e só `/ssr` tem os produtos no HTML", 1,
    "Right. The home page's list is built by `app.js` in a browser; `/ssr` arrives with it written in.",
    "Certo. A lista da página inicial é montada pelo `app.js` num navegador; `/ssr` já chega com ela escrita."),
   ("The home page was still loading when curl read it", "A página inicial ainda estava carregando quando o curl a leu", 0,
    "curl waits for the whole response; the products are simply not in it, however long you wait.",
    "O curl espera a resposta inteira; os produtos só não estão nela, por mais que se espere."),
   ("`/` writes its headings as `<h1>`", "`/` escreve os títulos como `<h1>`", 0,
    "Its cards use `<h2>` too, once a browser has drawn them; the HTML has no cards at all.",
    "Os cartões dela também usam `<h2>`, depois que um navegador os desenha; o HTML não tem cartão nenhum."),
   ("curl is refused by the home page", "A página inicial recusa o curl", 0,
    "The server answers curl like any client; the answer just holds an empty list.",
    "O servidor responde ao curl como a qualquer cliente; a resposta só traz uma lista vazia.")]))

X.append(quiz('ex-10cta8nw', 'what-arrives', 'medium',
  ("On a slow phone, what does a person see first on the server-rendered page that they do not see on the client-rendered one?",
   "Num celular lento, o que uma pessoa vê primeiro na página renderizada no servidor e não vê na renderizada no cliente?"),
  [("A spinner while the products are fetched", "Um indicador girando enquanto os produtos são buscados", 0,
    "No product request is needed on `/ssr`: the products are in the document.",
    "Em `/ssr` não há requisição de produtos: eles estão no documento."),
   ("Working buttons, before the HTML", "Botões funcionando, antes do HTML", 0,
    "Nothing comes before the HTML, and the buttons work only after `/slow/ssr.js` has run.",
    "Nada vem antes do HTML, e os botões só funcionam depois que o `/slow/ssr.js` rodou."),
   ("The products, as soon as the HTML arrives", "Os produtos, assim que o HTML chega", 1,
    "Right. They are written into the document, so they show without waiting for any script.",
    "Certo. Eles estão escritos no documento, então aparecem sem esperar script nenhum."),
   ("Nothing different; the two pages are identical on screen at every moment", "Nada diferente; as duas páginas são idênticas na tela em todo momento", 0,
    "They end up alike, but `/` shows an empty list until its script has run and asked.",
    "Elas terminam parecidas, mas `/` mostra uma lista vazia até o script dela rodar e pedir.")]))

X.append(cloze('ex-hdst9k2s', 'what-arrives', 'easy',
  ("When the browser builds the content from data a script fetched, the page uses ___ -side rendering.",
   "Quando o navegador monta o conteúdo a partir de dados que um script buscou, a página usa renderização no ___ ."),
  [(["client"], ["cliente"])]))

# ---- hydration --------------------------------------------------------------

X.append(quiz('ex-fk6jq1ry', 'hydration', 'medium',
  ("The first test clicks Banana's button on `/ssr` and the click raises no error, yet the basket stays at 0. Why did Playwright click without complaint?",
   "O primeiro teste clica no botão da banana em `/ssr` e o clique não dá erro, mas a cesta fica em 0. Por que o Playwright clicou sem reclamar?"),
  [("The button was visible, stable and enabled, which is all its checks look at", "O botão estava visível, parado e habilitado, que é tudo o que as verificações olham", 1,
    "Right. Nothing on the outside of a button says whether it has a click handler.",
    "Certo. Nada no lado de fora de um botão diz se ele tem uma função de clique."),
   ("It clicks without checking anything", "Ele clica sem verificar nada", 0,
    "It checks actionability before every click; the button simply passed.",
    "Ele verifica a acionabilidade antes de todo clique; o botão simplesmente passou."),
   ("The button was covered by the toast", "O botão estava coberto pelo aviso", 0,
    "`/ssr` has no toast, and a covered button would have made Playwright wait.",
    "`/ssr` não tem aviso, e um botão coberto teria feito o Playwright esperar."),
   ("The click was sent to the wrong card", "O clique foi para o cartão errado", 0,
    "Any card would have done; no button had a handler yet.",
    "Qualquer cartão serviria; nenhum botão tinha função ainda.")]))

X.append(numeric('ex-k6axkb6b', 'hydration', 'easy',
  ("In `app/routes/ssr.js`, for how many milliseconds does the server hold back `/slow/ssr.js`?",
   "Em `app/routes/ssr.js`, por quantos milissegundos o servidor segura o `/slow/ssr.js`?"),
  1500, ("ms", "ms"), tolerance=0,
  hint=("Look at the argument to `pause`.", "Olhe o argumento de `pause`.")))

X.append(quiz('ex-xhchfe33', 'hydration', 'hard',
  ("Suppose the server's pause were cut to 20 ms. What would the test that clicks at once most likely become?",
   "Suponha que a pausa do servidor caísse para 20 ms. O que o teste que clica na hora provavelmente viraria?"),
  [("A test that always passes", "Um teste que sempre passa", 0,
    "It would still click with no wait for the handler; a busy machine could still lose the race.",
    "Ele ainda clicaria sem esperar a função; uma máquina ocupada ainda poderia perder a corrida."),
   ("A test that still always fails", "Um teste que ainda falha sempre", 0,
    "With the gap that short, the script would often run before the click.",
    "Com uma lacuna tão curta, o script muitas vezes rodaria antes do clique."),
   ("A flaky test, passing or failing with the machine's speed", "Um teste intermitente, que passa ou falha conforme a velocidade da máquina", 1,
    "Right. The race is still there, only narrower, which is the shape of lesson 14's flaky tests.",
    "Certo. A corrida continua lá, só mais estreita, que é a forma dos testes intermitentes da aula 14."),
   ("A test that errors before it reaches the click", "Um teste que dá erro antes de chegar ao clique", 0,
    "Nothing before the click depends on the pause.", "Nada antes do clique depende da pausa.")]))

# ---- waiting-for-ready ------------------------------------------------------

X.append(quiz('ex-vktat48n', 'waiting-for-ready', 'medium',
  ("Why does `await expect(button).toBeEnabled()` before the click not fix the test on `/ssr`?",
   "Por que `await expect(button).toBeEnabled()` antes do clique não conserta o teste em `/ssr`?"),
  [("It waits too long and the test times out", "Ele espera demais e o teste estoura o tempo", 0,
    "It does not wait at all: the button is enabled from the start.",
    "Ele nem espera: o botão está habilitado desde o início."),
   ("The button is enabled before its handler exists, so it passes at once", "O botão está habilitado antes de a função existir, e ela passa na hora", 1,
    "Right. A wait helps only if what it watches changes when the page becomes ready.",
    "Certo. Uma espera só ajuda se o que ela observa muda quando a página fica pronta."),
   ("Playwright has no such assertion", "O Playwright não tem essa asserção", 0,
    "It has it; it just watches the wrong property for this page.",
    "Tem; ela só observa a propriedade errada para esta página."),
   ("It only works on `<input>` elements", "Ela só funciona em elementos `<input>`", 0,
    "It works on buttons too.", "Funciona em botões também.")]))

X.append(quiz('ex-a0n7dj85', 'waiting-for-ready', 'medium',
  ("Which of these wait for something that happens only after `ssr.js` has run? Choose all that apply.",
   "Quais destas esperam algo que só acontece depois que o `ssr.js` rodou? Escolha todas as que se aplicam."),
  [("`expect(page.locator('body')).toHaveAttribute('data-ready', 'true')`", "`expect(page.locator('body')).toHaveAttribute('data-ready', 'true')`", 1,
    "Right. The script sets the attribute as its last line.", "Certo. O script põe o atributo na última linha."),
   ("`page.waitForResponse('**/slow/ssr.js')`", "`page.waitForResponse('**/slow/ssr.js')`", 0,
    "It fires when status and headers arrive, before the script has run.",
    "Dispara quando o status e os cabeçalhos chegam, antes de o script rodar."),
   ("`expect(page.getByTestId('basket-count')).toHaveText('1')` after a click", "`expect(page.getByTestId('basket-count')).toHaveText('1')` depois de um clique", 1,
    "Right. Only a wired button can change the count, so this can only pass after the script ran.",
    "Certo. Só um botão com função muda a contagem, então isto só passa depois que o script rodou."),
   ("`expect(button).toBeEnabled()`", "`expect(button).toBeEnabled()`", 0,
    "The buttons are enabled in the server's HTML, before any script.",
    "Os botões estão habilitados no HTML do servidor, antes de qualquer script.")],
  multi=True))

X.append(quiz('ex-vbsw50ra', 'waiting-for-ready', 'hard',
  ("The developers agree to send the buttons `disabled` and enable each one in `ssr.js`. What happens to the first test, the one that clicks at once?",
   "Os desenvolvedores aceitam enviar os botões `disabled` e habilitar cada um no `ssr.js`. O que acontece com o primeiro teste, o que clica na hora?"),
  [("It passes unchanged: the click now waits for the button to be enabled", "Passa sem mudança: o clique agora espera o botão ficar habilitado", 1,
    "Right. Actionability already includes enabled, so the page's honesty does the waiting.",
    "Certo. A acionabilidade já inclui estar habilitado, então a honestidade da página faz a espera."),
   ("It fails sooner, because clicking a disabled button is an error", "Falha mais cedo, porque clicar num botão desabilitado é erro", 0,
    "Playwright waits for a disabled button to become enabled before it gives up.",
    "O Playwright espera um botão desabilitado ficar habilitado antes de desistir."),
   ("It still fails, and now needs the marker as well", "Ainda falha, e agora precisa da marca também", 0,
    "The run in the section passed with no change to the test.",
    "A execução da seção passou sem mudança no teste."),
   ("It passes only with `--workers 1`", "Só passa com `--workers 1`", 0,
    "Workers decide how many tests run at once, not how a click waits.",
    "Os workers decidem quantos testes rodam juntos, não como um clique espera.")]))

# ---- javascript-off ---------------------------------------------------------

X.append(quiz('ex-5tnb5t42', 'javascript-off', 'easy',
  ("With `test.use({ javaScriptEnabled: false })`, how many products does `/ssr` show, and how many does `/` show?",
   "Com `test.use({ javaScriptEnabled: false })`, quantos produtos `/ssr` mostra, e quantos `/` mostra?"),
  [("Eight and eight", "Oito e oito", 0,
    "`/` needs `app.js` to draw anything, and it never runs.", "`/` precisa do `app.js` para desenhar algo, e ele nunca roda."),
   ("Eight and none", "Oito e nenhum", 1,
    "Right. The server wrote `/ssr`'s products into the HTML; `/` waits for a script that never runs.",
    "Certo. O servidor escreveu os produtos de `/ssr` no HTML; `/` espera um script que nunca roda."),
   ("None and none", "Nenhum e nenhum", 0,
    "Switching scripts off does not remove what is already in the HTML.",
    "Desligar os scripts não tira o que já está no HTML."),
   ("None and eight", "Nenhum e oito", 0,
    "That is the two pages swapped.", "São as duas páginas trocadas.")]))

X.append(quiz('ex-7zrq0zx4', 'javascript-off', 'hard',
  ("The test `/ssr lists its eight products without a script` passes. A colleague wants to rename it `the shop works without JavaScript`. What is wrong with that?",
   "O teste `/ssr lists its eight products without a script` passa. Um colega quer renomeá-lo para `the shop works without JavaScript`. O que há de errado nisso?"),
  [("Nothing; the two names say the same thing", "Nada; os dois nomes dizem a mesma coisa", 0,
    "One claims content, the other claims behaviour, and only content was checked.",
    "Um afirma conteúdo, o outro comportamento, e só o conteúdo foi verificado."),
   ("Test names may not contain the word JavaScript", "Nomes de teste não podem conter a palavra JavaScript", 0,
    "Playwright accepts any string as a name; the problem is what it claims.",
    "O Playwright aceita qualquer texto como nome; o problema é o que ele afirma."),
   ("The new name would make the test fail", "O nome novo faria o teste falhar", 0,
    "A name changes nothing in what runs; it changes what a reader believes.",
    "Um nome não muda nada no que roda; muda o que quem lê acredita."),
   ("The buttons do nothing without a script, and the test never presses one", "Os botões não fazem nada sem script, e o teste nunca aperta um", 1,
    "Right. A test proves what it asserts; this one asserts that products are listed.",
    "Certo. Um teste prova o que afirma; este afirma que os produtos estão listados.")]))

X.append(quiz('ex-s4spb74j', 'javascript-off', 'medium',
  ("Why does the second test, `/ lists nothing without a script`, carry a comment saying it is a fact and not a requirement?",
   "Por que o segundo teste, `/ lists nothing without a script`, tem um comentário dizendo que é um fato e não um requisito?"),
  [("Playwright skips tests without a comment", "O Playwright pula testes sem comentário", 0,
    "Comments are ignored by the runner; they are for people.", "O executor ignora comentários; eles são para pessoas."),
   ("So nobody defends an empty home page as if somebody had asked for it", "Para ninguém defender uma página vazia como se alguém a tivesse pedido", 1,
    "Right. The day the team wants products without JavaScript, this test is the one to turn round.",
    "Certo. No dia em que a equipe quiser produtos sem JavaScript, este é o teste a virar."),
   ("Because the test fails and the comment explains why", "Porque o teste falha e o comentário explica por quê", 0,
    "It passes; the comment explains what its passing means.", "Ele passa; o comentário explica o que esse passar significa."),
   ("To turn the check off on build servers", "Para desligar a verificação nos servidores de build", 0,
    "A comment turns nothing off.", "Um comentário não desliga nada.")]))

# ---- choosing-the-layer -----------------------------------------------------

X.append(quiz('ex-vp8yts21', 'choosing-the-layer', 'medium',
  ("A test that asks only for the `request` fixture checks `/ssr`. What does it never do?",
   "Um teste que pede só a fixture `request` verifica `/ssr`. O que ele nunca faz?"),
  [("Send an HTTP request", "Enviar uma requisição HTTP", 0,
    "Sending requests is all it does.", "Enviar requisições é tudo o que ele faz."),
   ("Use the config's `baseURL`", "Usar o `baseURL` da configuração", 0,
    "It does: `request.get('/ssr')` resolves against it.", "Usa: `request.get('/ssr')` é resolvido a partir dele."),
   ("Open a page, so no script on it ever runs", "Abrir uma página, então nenhum script dela roda", 1,
    "Right. It reads the HTML as text, which is why it is fast and why it cannot see `/`'s products.",
    "Certo. Ele lê o HTML como texto, por isso é rápido e por isso não vê os produtos de `/`."),
   ("Read the response body", "Ler o corpo da resposta", 0,
    "`.text()` reads it; that is how the test finds the headings.", "O `.text()` o lê; é assim que o teste acha os títulos.")]))

X.append(quiz('ex-zpt2k0yr', 'choosing-the-layer', 'hard',
  ("A team checks `/ssr` only with HTTP tests that read its HTML. Which defect from this lesson would get past them?",
   "Uma equipe verifica `/ssr` só com testes HTTP que leem o HTML. Que defeito desta aula passaria por eles?"),
  [("A product missing from the HTML", "Um produto faltando no HTML", 0,
    "That is exactly what the HTML test compares against the API.", "É exatamente o que o teste de HTML compara com a API."),
   ("The second and a half when the buttons ignore clicks", "O segundo e meio em que os botões ignoram cliques", 1,
    "Right. The HTML was right throughout; the defect is in what happens after it arrives.",
    "Certo. O HTML esteve certo o tempo todo; o defeito está no que acontece depois que ele chega."),
   ("A price written in the wrong format", "Um preço escrito no formato errado", 0,
    "The price is in the HTML, so a test that reads it can check it.", "O preço está no HTML, então um teste que o lê consegue verificá-lo."),
   ("The route answering `404`", "A rota respondendo `404`", 0,
    "Any HTTP test sees the status first.", "Qualquer teste HTTP vê o status primeiro.")]))

X.append(matching('ex-wxtrcm7n', 'choosing-the-layer', 'medium',
  ("Match each question to the cheapest test in this lesson that can answer it.",
   "Ligue cada pergunta ao teste mais barato desta aula que consegue respondê-la."),
  [("Does the HTML of `/ssr` name every product?", "O HTML de `/ssr` nomeia todos os produtos?",
    "A request with no browser", "Uma requisição sem navegador"),
   ("Does a click on `/ssr` add to the basket?", "Um clique em `/ssr` põe na cesta?",
    "A browser test that waits for the marker", "Um teste de navegador que espera a marca"),
   ("Does `/ssr` show its products when scripts are off?", "`/ssr` mostra os produtos com scripts desligados?",
    "A browser with `javaScriptEnabled: false`", "Um navegador com `javaScriptEnabled: false`"),
   ("Are the products drawn on `/`?", "Os produtos são desenhados em `/`?",
    "A browser that runs `app.js`", "Um navegador que roda o `app.js`")]))

# ---- drill ------------------------------------------------------------------

X.append(ordering('ex-2474s8f9', 'drill', 'medium',
  ("Put what happens on `/ssr` in order, from the request to a click that works.",
   "Ponha em ordem o que acontece em `/ssr`, da requisição a um clique que funciona."),
  [("The HTML arrives with the eight products in it", "O HTML chega com os oito produtos"),
   ("The `load` event fires and `page.goto` returns", "O evento `load` dispara e o `page.goto` retorna"),
   ("The inline script asks for `/slow/ssr.js`", "O script embutido pede `/slow/ssr.js`"),
   ("`ssr.js` runs and sets `data-ready`", "O `ssr.js` roda e põe `data-ready`")],
  trap=("The script is asked for only after `load`, so `goto` returns before it has even been requested.",
        "O script só é pedido depois do `load`, então o `goto` retorna antes de ele sequer ser pedido.")))

X.append(quiz('ex-qcgg6p0r', 'drill', 'hard',
  ("Another shop renders on the server and sets no ready marker. Its buttons are enabled from the start. What should a tester do first?",
   "Outra loja renderiza no servidor e não põe marca de pronto. Os botões vêm habilitados desde o início. O que quem testa deve fazer primeiro?"),
  [("Add a fixed two-second wait before every click", "Pôr uma espera fixa de dois segundos antes de todo clique", 0,
    "It slows every test and still fails the day the script takes longer.",
    "Deixa todo teste mais lento e ainda falha no dia em que o script demorar mais."),
   ("Retry each click until the basket changes", "Repetir cada clique até a cesta mudar", 0,
    "A retried click can count twice once the handler arrives between tries.",
    "Um clique repetido pode contar duas vezes se a função chegar entre as tentativas."),
   ("Wait for `networkidle` and move on", "Esperar `networkidle` e seguir", 0,
    "Its documentation discourages it for tests, and a page that polls never goes quiet.",
    "A documentação o desaconselha para testes, e uma página que consulta o servidor nunca fica quieta."),
   ("Ask for the buttons to be disabled until their handlers exist", "Pedir que os botões fiquem desabilitados até a função existir", 1,
    "Right. It fixes the page for people too, and Playwright's own check then does the waiting.",
    "Certo. Corrige a página para as pessoas também, e a verificação do próprio Playwright faz a espera.")]))

X.append(quiz('ex-rrwat3jw', 'drill', 'medium',
  ("`npx playwright test tests/ssr.spec.js --repeat-each 5` with two workers once failed with `Received: \"2\"`. What is the likeliest cause?",
   "`npx playwright test tests/ssr.spec.js --repeat-each 5` com dois workers falhou uma vez com `Received: \"2\"`. Qual a causa mais provável?"),
  [("Two copies ran at once and shared the shop's one basket", "Duas cópias rodaram juntas e dividiram a cesta única da loja", 1,
    "Right. One copy's click landed in the other's count; lesson 15 is about that.",
    "Certo. O clique de uma cópia caiu na contagem da outra; a aula 15 trata disso."),
   ("The marker was set before the buttons were wired", "A marca foi posta antes de os botões terem função", 0,
    "`ssr.js` sets it on its last line, after the loop.", "O `ssr.js` a põe na última linha, depois do laço."),
   ("The reset in `beforeEach` failed", "A reinicialização do `beforeEach` falhou", 0,
    "A failed reset would leave old items, not add one more during the test.",
    "Uma reinicialização falha deixaria itens antigos, e não somaria um durante o teste."),
   ("Playwright clicked twice", "O Playwright clicou duas vezes", 0,
    "`click()` clicks once; the second item came from another copy of the test.",
    "O `click()` clica uma vez; o segundo item veio de outra cópia do teste.")]))

L = '/home/user/schooling/content/code/courses/web-automation/lessons/le-gw3wp01t'
write(L, X)
