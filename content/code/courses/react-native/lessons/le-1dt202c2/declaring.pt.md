---
title: Declarando a localização, e pedindo menos
version: 1
---

Instale o `expo-location`:

```
ana@dev:~/planner$ npx expo install expo-location
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 1 package, and audited 1123 packages in 7s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O plugin dele escreve as declarações das duas plataformas, e as opções dizem o que o planner nunca vai
pedir. Acrescente esta entrada à lista `"plugins"` do `app.json`:

```json
[
  "expo-location",
  {
    "locationWhenInUsePermission": "If you turn it on, the planner notes roughly where you study, to about a kilometre.",
    "locationAlwaysAndWhenInUsePermission": false,
    "locationAlwaysPermission": false,
    "locationFullAccuracyPermission": false,
    "motionUsagePermission": false,
    "isIosReducedAccuracyByDefault": true
  }
]
```

**O `locationWhenInUsePermission` é a frase que o iOS mostra**, e ela diz as três coisas que importam: é
opcional, para que serve, e com que precisão. As opções `false` tiram as frases de localização em segundo
plano, de um pedido temporário de precisão total e dos sensores de movimento, então o iOS não tem nada a
mostrar para nenhum deles e o planner não consegue pedir. O `isIosReducedAccuracyByDefault` é o pedido de
posições aproximadas desde o começo, no iOS.

```
ana@dev:~/planner$ grep -A10 "\"expo-location\"" app.json
        "expo-location",
        {
          "locationWhenInUsePermission": "If you turn it on, the planner notes roughly where you study, to about a kilometre.",
          "locationAlwaysAndWhenInUsePermission": false,
          "locationAlwaysPermission": false,
          "locationFullAccuracyPermission": false,
          "motionUsagePermission": false,
          "isIosReducedAccuracyByDefault": true
        }
      ]
    ]
ana@dev:~/planner$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep LOCATION android/app/src/main/AndroidManifest.xml
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
ana@dev:~/planner$ grep -A1 NSLocation ios/Studyplanner/Info.plist
    <key>NSLocationDefaultAccuracyReduced</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>If you turn it on, the planner notes roughly where you study, to about a kilometre.</string>
```

No iOS, o `NSLocationDefaultAccuracyReduced` é o padrão aproximado, e a frase é a única descrição de uso
para localização. No Android, o manifest declara tanto `ACCESS_COARSE_LOCATION` quanto
`ACCESS_FINE_LOCATION`, porque o Android 12 só mostra a escolha *precisa ou aproximada* a um app que
declara as duas: quem escolhe é a pessoa, não o manifest. O planner funciona igual com qualquer uma, já
que arredonda o que recebe.
