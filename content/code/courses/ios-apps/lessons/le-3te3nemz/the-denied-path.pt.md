---
title: Quando a resposta é não
version: 1
---

**Quem diz não não quebrou o app, e o app tem de continuar funcionando para essa pessoa.** A diretriz
5.1.1(iv) das App Review Guidelines, lida em 30 de outubro de 2026, diz que os apps "must respect
the user's permission settings" e, "where possible, provide alternative solutions for users who
don't grant consent". Para o planner isso é fácil de dizer: uma sessão sem foto continua sendo uma
sessão. O botão da câmera muda; nada mais muda.

O iOS nunca mostra o alerta uma segunda vez, então o app não pode perguntar de novo. O que ele pode
é dizer o que está desligado e oferecer o único lugar onde a pessoa pode mudar isso: a página do app
nos Ajustes, que o `UIApplication.openSettingsURLString` abre. **Faça isso com uma frase e um botão,
no lugar onde a câmera estaria**, e não com um alerta que bloqueia a tela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l18-states\" aria-label=\"Os quatro estados de uma permissão. Ela começa como notDetermined. O pedido do app mostra o alerta do sistema, uma vez; Permitir leva a authorized e Não Permitir a denied. De denied, só a pessoa volta, ligando a chave no app Ajustes. Um quarto estado, restricted, é definido por outra pessoa, o Tempo de Uso de um responsável ou um gerenciador do aparelho, e o app não tem como tirar a pessoa dele.\"><defs><marker id=\"l18-states-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l18-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l18-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">notDetermined</text><text x=\"95\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ninguém perguntou</text><rect x=\"250\" y=\"95\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"335\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o alerta do sistema</text><text x=\"335\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua frase de uso</text><text x=\"335\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mostrado uma vez</text><path d=\"M170 135 L248 135\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-states-ah-amber)\"></path><text x=\"209\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pedido</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">authorized</text><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a câmera abre</text><rect x=\"510\" y=\"190\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">denied</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma frase e os Ajustes</text><path d=\"M420 115 L508 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-states-ah-phosphor)\"></path><text x=\"455\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Permitir</text><path d=\"M420 155 L508 210\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-states-ah-wire)\"></path><text x=\"448\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Não Permitir</text><path d=\"M690 205 C 715 160, 715 110, 692 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-states-ah-paper-dim)\"></path><text x=\"640\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a pessoa, nos Ajustes</text><rect x=\"20\" y=\"220\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">restricted</text><text x=\"170\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">definido por outra pessoa; o app não tira dele</text></svg>", "caption": "O app tira uma permissão de notDetermined uma vez. Depois disso, só a pessoa a muda, e só nos Ajustes."}
```

## A decisão, em Swift puro

O que o botão mostra depende do estado e de mais nada, então a decisão pode ser uma função do
estado, e uma função de valores simples roda em qualquer lugar. Os quatro estados são os que o
`AVCaptureDevice` informa, escritos como uma enumeração do próprio planner para que este arquivo não
precise de nenhum framework da Apple. Salve-o como `denied.swift` em `~/privacy`:

```schooling-example
{"language": "swift", "file": "denied.swift", "parts": [{"code": "// denied.swift: what the camera button shows, for each answer the person may have given\nenum CameraAccess: CaseIterable {\n    case notDetermined, authorized, denied, restricted\n}\n\nenum CameraButton: Equatable {\n    case ask(String)\n    case takePhoto\n    case openSettings(String)\n    case unavailable(String)\n}\n", "note": "A cópia do planner dos quatro estados, e as quatro coisas que o botão pode ser. O `CaseIterable` deixa o laço abaixo percorrer todos os estados, então um quinto acrescentado depois é impresso também."}, {"code": "func button(for access: CameraAccess) -> CameraButton {\n    switch access {\n    case .notDetermined: .ask(\"Take a photo of your notes\")\n    case .authorized: .takePhoto\n    case .denied: .openSettings(\"Camera is off for Planner. You can turn it on in Settings.\")\n    case .restricted: .unavailable(\"The camera is not available on this device.\")\n    }\n}\n", "note": "Sem `default`: o compilador confere que todo estado tem resposta. O `.restricted` não ganha botão de Ajustes, porque a pessoa com o telefone não muda uma restrição que outra pessoa definiu."}, {"code": "for access in CameraAccess.allCases {\n    print(access, \"->\", button(for: access))\n}\n", "note": "Uma linha por estado. Cada frase diz o que está desligado e o que dá para fazer, sem culpar a pessoa pela resposta que deu."}]}
```

```
ana@vm:~/privacy$ swift denied.swift
notDetermined -> ask("Take a photo of your notes")
authorized -> takePhoto
denied -> openSettings("Camera is off for Planner. You can turn it on in Settings.")
restricted -> unavailable("The camera is not available on this device.")
```

**`.denied` e `.restricted` parecem iguais e não são.** Os dois querem dizer sem câmera, e uma tela
que mostrasse uma mensagem só para os dois mandaria alguém cujo telefone é gerenciado pela escola
para uma página de Ajustes onde a chave está acinzentada. A metade em SwiftUI, que não foi
executada, transforma cada valor num controle:

```swift
// CameraButtonView.swift
import SwiftUI
import UIKit

struct CameraButtonView: View {
    let state: CameraButton
    var takePhoto: () -> Void

    var body: some View {
        switch state {
        case .ask(let title):
            Button(title, action: takePhoto)
        case .takePhoto:
            Button("Take a photo of your notes", action: takePhoto)
        case .openSettings(let text):
            VStack(alignment: .leading) {
                Text(text)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        case .unavailable(let text):
            Text(text)
        }
    }
}
```

Os dois botões `Take a photo` chamam a mesma ação: na primeira vez que ela roda, a chamada da ação ao
`requestAccess` da seção 03 mostra o alerta, e em todas as vezes seguintes ela abre a câmera.
