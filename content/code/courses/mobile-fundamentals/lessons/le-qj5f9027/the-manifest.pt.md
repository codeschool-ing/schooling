---
title: O privacy manifest, os motivos que a Apple pede, e pedir para rastrear
version: 1
---

**No iOS o formulário tem uma segunda metade que vive dentro do app: um arquivo chamado
`PrivacyInfo.xcprivacy`, o privacy manifest.** O formulário da App Store é preenchido por uma pessoa,
uma vez por versão. O manifest é uma property list embutida no app e em cada SDK de terceiros, e a
documentação da Apple sobre arquivos de privacy manifest diz que ele registra duas coisas: os tipos de
dados que o app ou SDK coleta, e as *required reason APIs*, APIs que exigem motivo, que ele usa. O Xcode
consegue reunir todos os manifests de um app num relatório de privacidade, então quem preenche o
formulário parte do que o código diz em vez da memória.

## Motivos obrigatórios: APIs que poderiam identificar o aparelho

**Algumas APIs comuns também servem para identificar um aparelho, então a Apple pede o motivo de cada
uso.** A documentação da Apple sobre descrever o uso de required reason APIs diz que essas APIs "podem
ser mal usadas para acessar sinais do aparelho na tentativa de identificar o aparelho ou o usuário, o
que também se chama fingerprinting", e que fingerprinting não é permitido, tenha a pessoa dado
permissão para rastrear ou não. Lidas em 30 de outubro de 2026, as categorias que ela lista são
timestamps de arquivo, horário de inicialização do sistema, espaço em disco, teclados ativos e user
defaults. Um app que usa uma delas declara a categoria e um ou mais motivos aprovados, cada um um código
curto com uma frase de significado, e só pode usar a API por esses motivos. A mesma página diz que, a
partir de 1º de maio de 2024, apps que não descrevem o uso dessas APIs "não são aceitos pelo App Store
Connect".

**O planner no iOS esbarraria em exatamente uma delas.** Guardar um ajuste pequeno, como se os lembretes
estão ligados, em `UserDefaults` é a categoria user defaults, e o motivo para dados que só o próprio app
lê e escreve é `CA92.1`. O manifest inteiro dele seria este, adaptado da documentação da Apple e **não
construído nem enviado para este curso**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- PrivacyInfo.xcprivacy: the planner collects nothing and tracks nothing -->
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Dois arrays vazios carregam a maior parte do significado.** `NSPrivacyTracking` é `false` e não há
domínios de tracking, porque o planner não rastreia ninguém; `NSPrivacyCollectedDataTypes` está vazio,
porque nada sai do celular. Um manifest é curto quando um app é modesto, e cresce exatamente na
velocidade em que cresce o apetite do app por dados.

**Cada SDK traz o próprio manifest, e o do app não o cobre.** A documentação da Apple sobre o uso de
dados em privacy manifests diz que SDKs de terceiros "precisam fornecer os próprios arquivos de privacy
manifest", e a página dos motivos obrigatórios diz que um SDK não pode contar com o manifest do app para
informar o próprio uso dessas APIs. O relatório de privacidade é a soma. Acrescentar um SDK de analytics
acrescenta o manifest dele à soma, e esse é muitas vezes o primeiro momento em que uma equipe vê, num
lugar só, o que a biblioteca coleta.

## Pedir para rastrear

**Um app iOS que rastreia precisa perguntar antes, com um diálogo próprio e uma frase própria.** A
documentação da Apple sobre o framework App Tracking Transparency diz que um app precisa dele "se coleta
dados sobre as pessoas e os compartilha com outras empresas para rastreá-las entre apps e sites". O app
acrescenta uma purpose string `NSUserTrackingUsageDescription`, como as da aula 12, e chama
`requestTrackingAuthorization` para mostrar o pedido. O `NSPrivacyTrackingDomains` do privacy manifest
lista os domínios que o app contata para rastrear, e a documentação do manifest diz que, se a pessoa não
concedeu o rastreamento, os pedidos a esses domínios falham.

**O Android não tem um equivalente único, e o formulário Data safety carrega o peso lá.** Desde o
Android 14, observa o guia do Android para desenvolvedores sobre o formulário, detalhes das práticas de
um app com dados de localização aparecem no próprio diálogo de permissão de localização do sistema,
então a declaração chega à pessoa no momento em que ela decide, não só na página da loja.

Para o planner, nada nesta seção pede mais do que o arquivo curto acima: ele não rastreia, então nunca
mostra o diálogo de tracking, e declara um motivo de API. É o trabalho de privacidade mais barato que um
app pode ter, e as duas próximas seções mostram que isso foi uma escolha.
