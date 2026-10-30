"""Exam questions for lesson 20 (le-1ytvc9af). Ids are assigned by the coordinator."""
import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from exgen import Q, C

H = ("Lesson 20.", "Aula 20.")

QS = [
Q(None, None, "ordering", "easy",
  ("Put Google Play's release stages in order, from the narrowest audience to the widest.",
   "Ponha em ordem as etapas de lançamento do Google Play, do público mais estreito ao mais amplo."),
  hint=H, items=[("internal test", "teste interno"), ("closed test", "teste fechado"),
                 ("open test", "teste aberto"), ("production", "produção")]),
Q(None, None, "numeric", "medium",
  ("In Apple's seven-day phased release, what percentage of users with automatic updates have the new version on day 6?",
   "Na liberação em fases de sete dias da Apple, que porcentagem dos usuários com atualização automática tem a versão nova no dia 6?"),
  hint=H, value=50, tolerance=0),
Q(None, None, "cloze", "easy",
  ("On Android, the integer that must be higher in every new upload to Google Play is called ___.",
   "No Android, o inteiro que precisa ser maior a cada novo envio ao Google Play se chama ___."),
  hint=H, blanks=[(["versionCode", "version code"], ["versionCode", "version code"])]),
Q(None, None, "quiz", "medium",
  ("A release script compares version names as plain strings. Which mistake does it make?",
   "Um script de lançamento compara nomes de versão como textos simples. Que erro ele comete?"),
  hint=H, choices=[
   C(False, "It treats 1.9.2 and 1.9.20 as equal", "Trata 1.9.2 e 1.9.20 como iguais",
     "As strings they differ; the problem is the order.", "Como textos eles diferem; o problema é a ordem."),
   C(True, "It decides 1.10.0 is older than 1.9.2", "Decide que 1.10.0 é mais velha que 1.9.2",
     "Right: \"1\" sorts before \"9\" as a character, though 10 is more than 9.", "Isso: \"1\" vem antes de \"9\" como caractere, embora 10 seja mais que 9."),
   C(False, "It rejects names with three parts", "Recusa nomes com três partes",
     "String comparison accepts any text.", "A comparação de texto aceita qualquer texto."),
   C(False, "It compares the build numbers instead", "Compara os números de build no lugar",
     "It compares what it is given, wrongly.", "Compara o que recebe, do jeito errado."),
  ]),
Q(None, None, "quiz", "hard",
  ("A crash shows up two days into a phased release on iOS. The team pauses it. What is true of the users who already updated?",
   "Um travamento aparece dois dias depois do início de uma liberação em fases no iOS. A equipe pausa. O que é verdade sobre os usuários que já atualizaram?"),
  hint=H, choices=[
   C(False, "Their phones go back to the previous version", "Os celulares deles voltam para a versão anterior",
     "Nothing rolls a phone back; the fix is a newer build.", "Nada faz um celular voltar; a correção é um build mais novo."),
   C(False, "They are removed from the App Store until the fix", "Eles são tirados da App Store até a correção",
     "Users are not removed; the pause only stops new automatic updates.", "Usuários não são tirados; a pausa só interrompe novas atualizações automáticas."),
   C(True, "They keep the crashing version until a newer build reaches them", "Ficam com a versão que trava até um build mais novo chegar",
     "Right: pausing stops the spread, not the version.", "Isso: pausar interrompe a propagação, não a versão."),
   C(False, "Nothing changes for anybody, since a pause is cosmetic", "Nada muda para ninguém, já que a pausa é cosmética",
     "New users stop getting the update; that is the point of pausing.", "Usuários novos deixam de receber a atualização; esse é o ponto da pausa."),
  ]),
]
