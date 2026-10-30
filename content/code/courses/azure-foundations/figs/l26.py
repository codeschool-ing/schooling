"""Lesson 26: portal, command line and declared infrastructure."""
from figures import Fig, T, figure


@figure('l26-doors', 26)
def doors():
    f = Fig('l26-doors', 720, 300, T(
        'Three doors into Azure, left to right. The portal: you fill in forms, and nothing is written '
        'down. The command line: you write the steps. A declarative file, Bicep or Terraform: you write '
        'the result, and the tool works out the steps. All three end in the same PUT request to '
        'Resource Manager at management.azure.com, which creates vnet-shop-prod.',
        'Três portas para o Azure, da esquerda para a direita. O portal: você preenche formulários, e '
        'nada fica escrito. A linha de comando: você escreve os passos. Um arquivo declarativo, Bicep ou '
        'Terraform: você escreve o resultado, e a ferramenta calcula os passos. As três terminam no '
        'mesmo pedido PUT ao Resource Manager em management.azure.com, que cria vnet-shop-prod.'))
    doors = [(30, T('portal', 'portal'), T('you fill in forms', 'você preenche formulários'),
              T('nothing written down', 'nada fica escrito')),
             (260, T('command line', 'linha de comando'), T('you write the steps', 'você escreve os passos'),
              'az network vnet create'),
             (490, T('a declarative file', 'um arquivo declarativo'), T('you write the result', 'você escreve o resultado'),
              'main.bicep  main.tf')]
    for x, name, how, what in doors:
        f.rect(x, 24, 200, 96, stroke='--wire', fill='--panel')
        f.text(x + 100, 46, name, size=11, weight='600')
        f.text(x + 100, 70, how, size=10, fill='--paper')
        f.text(x + 100, 94, what, size=9.5, mono=(x > 30), fill='--paper-dim')
        f.arrow([(x + 100, 121), (x + 100, 150), (360 + (x - 260) * 0.25, 178)], stroke='--paper-dim', width=1.3)
    f.rect(220, 180, 280, 44, stroke='--amber', fill='--panel')
    f.text(360, 202, 'PUT .../virtualNetworks/vnet-shop-prod', size=10, mono=True)
    f.arrow([(360, 225), (360, 243)], stroke='--amber', width=1.3)
    f.rect(240, 244, 240, 40, stroke='--amber', fill='--scan')
    f.text(360, 264, 'Resource Manager', size=10.5, weight='600')
    return f, T('Three ways to ask, one request, one API answering it.',
                'Três jeitos de pedir, um pedido, uma API respondendo.')
