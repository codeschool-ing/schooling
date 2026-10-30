---
title: A câmera, e as fotos que não pedem permissão
version: 1
---

**Há duas formas de o planner conseguir a foto das anotações de alguém, e só uma delas precisa de
permissão.** A câmera precisa: o próprio app tira a foto, então tem de poder usar a câmera. Escolher
uma foto que já está na biblioteca não precisa, se o app deixar o sistema fazer a escolha. Nada nesta
seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para o
`AVCaptureDevice` e para o `PhotosPicker` do SwiftUI, lida em 30 de outubro de 2026.

## A câmera: pedir no momento do uso

O estado da câmera é um de quatro, e o app o lê antes de decidir qualquer coisa:

```swift
// CameraAccess.swift
import AVFoundation

func cameraAllowed() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
        return false
    @unknown default:
        return false
    }
}
```

**Só o `.notDetermined` leva ao alerta.** O `requestAccess` é a chamada que faz o iOS mostrar a frase
de uso da seção 02, e ela é respondida uma vez; depois o estado é `.authorized` ou `.denied` e a
chamada devolve essa resposta sem perguntar. `.restricted` quer dizer que outra pessoa, que não a que
segura o telefone, decidiu: um ajuste de Tempo de Uso de um responsável ou o gerenciamento de
aparelhos de uma empresa, e a pessoa também não consegue mudar. O `@unknown default` está ali porque
a Apple pode acrescentar um caso a essa enumeração num iOS futuro, e o compilador pede que você diga
agora o que um caso desconhecido significa. Aqui significa não.

Chame-a **quando a pessoa tocar no botão que tira a foto**, e não quando o app abre. O conselho da
Apple sobre localização, citado na seção 04, dá o motivo, e ele vale para toda permissão: perguntadas
fora de contexto, as pessoas dizem não, e a seção 02 mostrou que o não é permanente.

## Fotos: deixe o sistema escolher

Quem anexa a foto das suas anotações quer uma imagem, e não entregar uma biblioteca de dez mil. O
`PhotosPicker` do SwiftUI mostra o seletor de fotos do sistema num processo separado: o app só vê o
que a pessoa escolhe, e por isso **não precisa de permissão nem de frase de uso**. A documentação da
Apple para o `PHPickerViewController`, que o `PhotosPicker` embrulha, diz o mesmo, e a diretriz
5.1.1(iii) pede exatamente isso: "use the out-of-process picker or a share sheet rather than
requesting full access to protected resources like Photos".

```swift
// NotesPhotoButton.swift
import SwiftUI
import PhotosUI

struct NotesPhotoButton: View {
    @State private var item: PhotosPickerItem?
    @State private var image: Image?

    var body: some View {
        PhotosPicker("Attach a photo of your notes", selection: $item, matching: .images)
            .task(id: item) {
                image = try? await item?.loadTransferable(type: Image.self)
            }
    }
}
```

O `PhotosPickerItem` é um marcador do que a pessoa escolheu, e o `loadTransferable` carrega a imagem
em si, o que pode levar um instante para uma foto guardada no iCloud. **O `try?` joga o erro fora, e
aqui isso é uma escolha com motivo**: o exemplo de falha da documentação é uma imagem que não pode
ser baixada, e o botão continua utilizável para outra tentativa. Um app de verdade mostraria uma
linha dizendo que a foto não pôde ser carregada, e o estado de erro da aula 12 é a forma para isso.

O `NSPhotoLibraryUsageDescription`, acesso completo à biblioteca, é do que precisa um app que navega
ou edita a biblioteca inteira: um editor de fotos, uma ferramenta de backup. O planner não é nenhum
dos dois.
