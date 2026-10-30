"""The course exam, lesson 11: deep links and verified links. Ids are assigned by the coordinator."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("Two apps on one Android phone both declare the scheme notes://. A notes:// link is tapped. What decides which app opens?",
   "Dois apps num celular Android declaram o esquema notes://. Um link notes:// é tocado. O que decide qual app abre?"),
  hint=H(11), choices=[
   C(False, "Whichever app was installed first", "O app que foi instalado primeiro",
     "Installation order verifies nothing; the person is asked, or uses a default they set.", "A ordem de instalação não verifica nada; a pessoa é perguntada, ou usa um padrão que definiu."),
   C(True, "The person, through the system's choice dialog or a default they set", "A pessoa, pelo diálogo de escolha do sistema ou por um padrão que definiu",
     "Right: nothing checks a custom scheme's claim.", "Isso: nada confere a reivindicação de um esquema próprio."),
   C(False, "A file on a website", "Um arquivo num site",
     "Only https links are verified against a site.", "Só links https são verificados contra um site."),
   C(False, "The store, which registered the scheme", "A loja, que registrou o esquema",
     "No store registers schemes.", "Nenhuma loja registra esquemas."),
  ]),
Q(None, None, "multiple-choice", "medium",
  ("A website serves /.well-known/assetlinks.json. Which of these would make Android's verification fail? Choose all that apply.",
   "Um site serve /.well-known/assetlinks.json. Quais destes fariam a verificação do Android falhar? Escolha todas as que se aplicam."),
  hint=H(11), choices=[
   C(True, "a 301 redirect to another host", "um redirecionamento 301 para outro host", "Right: no redirects.", "Isso: nenhum redirecionamento."),
   C(True, "a fingerprint that is not the app's signing certificate", "uma impressão digital que não é a do certificado que assina o app", "Right.", "Isso."),
   C(True, "a 404 for that path", "um 404 nesse caminho", "Right: no file.", "Isso: arquivo nenhum."),
   C(False, "the file being readable by anyone", "o arquivo poder ser lido por qualquer um",
     "It is public by design.", "Ele é público de propósito."),
  ]),
Q(None, None, "quiz", "hard",
  ("An app opens a link straight on a detail screen. The person presses back once. Where should they be, by Android's navigation principles?",
   "Um app abre um link direto numa tela de detalhe. A pessoa aperta voltar uma vez. Onde ela deveria estar, pelos princípios de navegação do Android?"),
  hint=H(11), choices=[
   C(False, "Outside the app, because the stack held one screen", "Fora do app, porque a pilha tinha uma tela",
     "That is the stack nobody built; the principles ask for a synthetic one.", "Essa é a pilha que ninguém montou; os princípios pedem uma sintética."),
   C(True, "One level up, as if they had tapped their way in", "Um nível acima, como se tivesse entrado tocando",
     "Right: a synthetic back stack the person could have reached.", "Isso: uma pilha sintética que a pessoa poderia ter montado."),
   C(False, "On the app's last screen from the previous session", "Na última tela do app na sessão anterior",
     "Following a link replaces the old stack.", "Seguir um link substitui a pilha antiga."),
   C(False, "On a blank screen until the data loads", "Numa tela em branco até os dados carregarem",
     "Nothing about back empties a screen.", "Nada no voltar esvazia uma tela."),
  ]),
Q(None, None, "cloze", "easy",
  ("Android fetches a site's verification file from /.well-known/___.json.",
   "O Android busca o arquivo de verificação de um site em /.well-known/___.json."),
  hint=H(11), blanks=[(["assetlinks"], ["assetlinks"])]),
Q(None, None, "quiz", "medium",
  ("A person without the app taps a verified https link to a recipe. What should the website do?",
   "Uma pessoa sem o app toca num link https verificado para uma receita. O que o site deve fazer?"),
  hint=H(11), choices=[
   C(False, "Answer 404, since the link was meant for the app", "Responder 404, já que o link era para o app",
     "Then the link fails for everyone without the app.", "Aí o link falha para todo mundo sem o app."),
   C(False, "Redirect to the store at once", "Redirecionar para a loja na hora",
     "The person asked for a recipe, not an install.", "A pessoa pediu uma receita, não uma instalação."),
   C(True, "Serve a page about that recipe", "Servir uma página sobre aquela receita",
     "Right: the web page is part of the link.", "Isso: a página web faz parte do link."),
   C(False, "Nothing; the browser never opens a verified link", "Nada; o navegador nunca abre um link verificado",
     "Without the app, it is an ordinary web address.", "Sem o app, é um endereço web comum."),
  ]),
]
