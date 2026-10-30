"""The course exam, lesson 13: privacy declarations and data minimisation. Ids are assigned by the coordinator."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q(None, None, "quiz", "medium",
  ("A notes app keeps every note on the phone and sends nothing anywhere. What does it declare as collected on Apple's privacy form?",
   "Um app de notas guarda toda nota no celular e não envia nada a lugar nenhum. O que ele declara como coletado no formulário de privacidade da Apple?"),
  hint=H(13), choices=[
   C(False, "The notes, since the app stores them", "As notas, já que o app as guarda",
     "Collected means sent off the device; stored on it is not collected.", "Coletado quer dizer enviado para fora do aparelho; guardado nele não é coletado."),
   C(True, "Nothing", "Nada",
     "Right: nothing leaves the device.", "Isso: nada sai do aparelho."),
   C(False, "The notes, with App Functionality as the purpose", "As notas, com App Functionality como finalidade",
     "A purpose only applies to data that is collected.", "Uma finalidade só vale para dado coletado."),
   C(False, "Only the notes longer than a page", "Só as notas maiores que uma página",
     "Size has nothing to do with collection.", "O tamanho não tem nada a ver com coleta."),
  ]),
Q(None, None, "quiz", "hard",
  ("A weather app adds an advertising SDK that links its users' data with data from other companies' apps for targeted ads. On iOS, what must the app do before that happens?",
   "Um app de previsão do tempo acrescenta um SDK de anúncios que liga os dados dos usuários a dados de apps de outras empresas para anúncios direcionados. No iOS, o que o app precisa fazer antes disso?"),
  hint=H(13), choices=[
   C(False, "Nothing, as long as the SDK's own manifest declares it", "Nada, desde que o manifest do próprio SDK declare",
     "Declaring is not asking; tracking needs the person's permission first.", "Declarar não é perguntar; rastrear exige a permissão da pessoa antes."),
   C(False, "Add a required reason code for user defaults", "Acrescentar um código de motivo de user defaults",
     "That is unrelated to tracking.", "Isso não tem relação com tracking."),
   C(True, "Ask through App Tracking Transparency, and declare tracking on the label", "Perguntar pelo App Tracking Transparency, e declarar o tracking no rótulo",
     "Right: it is tracking in Apple's sense.", "Isso: é tracking no sentido da Apple."),
   C(False, "Ask for location permission", "Pedir a permissão de localização",
     "Location is a different permission.", "Localização é outra permissão."),
  ]),
Q(None, None, "cloze", "medium",
  ("On iOS, the file inside an app or SDK that records the data it collects and the required reason APIs it uses is called PrivacyInfo.___.",
   "No iOS, o arquivo dentro de um app ou SDK que registra os dados que ele coleta e as required reason APIs que usa se chama PrivacyInfo.___."),
  hint=H(13), blanks=[(["xcprivacy"], ["xcprivacy"])]),
Q(None, None, "matching", "medium",
  ("Match each data flow to what a store form calls it.", "Associe cada fluxo de dados ao nome que um formulário de loja dá a ele."),
  hint=H(13), pairs=[(("kept on the phone only", "guardado só no celular"), ("not collected", "não coletado")),
         (("sent to the developer's server and kept", "enviado ao servidor de quem desenvolve e guardado"), ("collected", "coletado")),
         (("sent by an SDK to its own company", "enviado por um SDK à própria empresa"), ("collected and shared", "coletado e compartilhado"))],
  distractors=[("exempt, since the code is a library", "isento, já que o código é uma biblioteca")]),
Q(None, None, "multiple-choice", "medium",
  ("Which of these must a team update when it adds a crash-reporting SDK that sends crash logs to its company? Choose all that apply.",
   "Quais destes uma equipe precisa atualizar quando acrescenta um SDK de crash que envia logs à própria empresa? Escolha todas as que se aplicam."),
  hint=H(13), choices=[
   C(True, "the Data safety form on Google Play", "o formulário Data safety no Google Play", "Right.", "Isso."),
   C(True, "the app privacy details in App Store Connect", "os privacy details do app no App Store Connect", "Right.", "Isso."),
   C(False, "the assetlinks.json on its website", "o assetlinks.json no site dela",
     "That file is about links, not data.", "Esse arquivo é sobre links, não dados."),
   C(False, "the purpose string for the camera", "a purpose string da câmera",
     "Crash logs have nothing to do with the camera.", "Logs de crash não têm nada a ver com a câmera."),
  ]),
]
