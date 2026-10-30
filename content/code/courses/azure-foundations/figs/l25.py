"""Lesson 25: Resource Manager, the API every door goes through."""
from figures import Fig, T, figure


@figure('l25-path', 25)
def path():
    f = Fig('l25-path', 720, 330, T(
        'The path of a request. On the left, the clients: the portal, the Azure CLI, Azure PowerShell, '
        'Bicep and Terraform. Step 1: the client gets a token from Microsoft Entra ID at '
        'login.microsoftonline.com. Step 2: it sends the request with the token to Resource Manager at '
        'management.azure.com. Step 3: Resource Manager checks the token, the role, the policies, the '
        'locks and the request limit. Step 4: it hands the request to the resource provider, such as '
        'Microsoft.Network, which does the work.',
        'O caminho de um pedido. À esquerda, os clientes: o portal, a CLI do Azure, o Azure PowerShell, '
        'o Bicep e o Terraform. Passo 1: o cliente obtém um token do Microsoft Entra ID em '
        'login.microsoftonline.com. Passo 2: ele manda o pedido com o token ao Resource Manager em '
        'management.azure.com. Passo 3: o Resource Manager confere o token, o papel, as políticas, as '
        'travas e o limite de pedidos. Passo 4: ele entrega o pedido ao resource provider, como o '
        'Microsoft.Network, que faz o trabalho.'))
    clients = [T('portal', 'portal'), 'az', 'Az PowerShell', 'Bicep', 'Terraform']
    f.rect(10, 30, 150, 260, stroke='--paper-dim', fill='--ink', dash='5 4')
    for i, c in enumerate(clients):
        y = 40 + i * 44
        f.rect(20, y, 130, 32, stroke='--wire', fill='--panel')
        f.text(85, y + 16, c, size=10, mono=(i > 0))
    f.text(85, 272, T('the clients', 'os clientes'), size=9.5, fill='--paper-dim')
    # entra
    f.rect(230, 20, 200, 56, stroke='--phosphor', fill='--panel')
    f.text(330, 40, 'Microsoft Entra ID', size=10.5, weight='600')
    f.text(330, 60, 'login.microsoftonline.com', size=9, mono=True, fill='--paper-dim')
    f.arrow([(161, 56), (229, 50)], stroke='--phosphor', width=1.3)
    f.text(190, 34, '1', size=11, weight='600', fill='--phosphor')
    # arm
    f.rect(230, 130, 200, 150, stroke='--amber', fill='--panel')
    f.text(330, 150, 'Resource Manager', size=10.5, weight='600')
    f.text(330, 168, 'management.azure.com', size=9, mono=True, fill='--paper-dim')
    checks = [T('token valid?', 'token válido?'), T('role allows it?', 'o papel permite?'),
              T('policy allows it?', 'a política permite?'), T('no lock?', 'sem trava?'),
              T('under the limit?', 'abaixo do limite?')]
    for i, c in enumerate(checks):
        f.text(330, 190 + i * 18, c, size=9.5, fill='--paper')
    f.arrow([(161, 166), (229, 190)], stroke='--amber', width=1.3)
    f.text(190, 168, '2', size=11, weight='600', fill='--amber')
    f.text(442, 205, '3', size=11, weight='600', fill='--amber')
    # provider
    f.rect(520, 160, 180, 80, stroke='--wire', fill='--scan')
    f.text(610, 184, T('resource provider', 'resource provider'), size=10, weight='600')
    f.text(610, 206, 'Microsoft.Network', size=10, mono=True)
    f.text(610, 224, T('does the work', 'faz o trabalho'), size=9.5, fill='--paper-dim')
    f.arrow([(431, 230), (519, 220)], stroke='--paper-dim', width=1.3)
    f.text(475, 214, '4', size=11, weight='600', fill='--paper-dim')
    f.text(475, 306, T('steps 2 to 4 are the same whichever client sent the request',
                       'os passos 2 a 4 são os mesmos qualquer que seja o cliente'),
           size=10, fill='--paper-dim')
    return f, T('Five clients, one token issuer, one API. Whatever is refused is refused in the middle.',
                'Cinco clientes, um emissor de tokens, uma API. O que é recusado é recusado no meio.')


@figure('l25-bucket', 25)
def bucket():
    f = Fig('l25-bucket', 720, 250, T(
        'A token bucket for subscription reads, drawn as a column of 250 tokens. A burst of 250 reads '
        'empties it in one go. After that, 25 tokens come back each second, so the script can go on at '
        '25 reads a second. A request when the bucket is empty is answered with 429 and a Retry-After.',
        'Um balde de tokens para leituras de assinatura, desenhado como uma coluna de 250 tokens. Uma '
        'rajada de 250 leituras o esvazia de uma vez. Depois disso, voltam 25 tokens por segundo, então o '
        'script pode seguir a 25 leituras por segundo. Um pedido com o balde vazio recebe 429 e um '
        'Retry-After.'))
    def bucket_at(x, filled, label, sub):
        f.rect(x, 40, 90, 150, stroke='--wire', fill='--ink')
        h = 150 * filled / 250
        if h:
            f.rect(x + 4, 190 - h + 4 if h > 8 else 182, 82, max(h - 8, 4), stroke=None, fill='--scan', rx=2)
        f.text(x + 45, 115, str(filled), size=13, weight='600', mono=True)
        f.text(x + 45, 208, label, size=10, weight='600')
        f.text(x + 45, 226, sub, size=9.5, fill='--paper-dim')
    bucket_at(40, 250, T('full', 'cheio'), T('250 tokens', '250 tokens'))
    bucket_at(240, 0, T('after a burst', 'depois de uma rajada'), T('250 reads at once', '250 leituras de uma vez'))
    bucket_at(440, 25, T('one second later', 'um segundo depois'), T('25 more', 'mais 25'))
    f.arrow([(131, 115), (239, 115)], stroke='--paper-dim', width=1.3)
    f.arrow([(331, 115), (439, 115)], stroke='--paper-dim', width=1.3)
    f.rect(560, 60, 140, 110, stroke='--amber', fill='--panel')
    f.text(630, 92, '429', size=16, weight='600', mono=True, fill='--amber')
    f.text(630, 118, 'Retry-After', size=10, mono=True)
    f.text(630, 140, T('if the bucket', 'se o balde'), size=9.5, fill='--paper-dim')
    f.text(630, 155, T('is empty', 'estiver vazio'), size=9.5, fill='--paper-dim')
    f.arrow([(285, 39), (285, 22), (630, 22), (630, 59)], stroke='--amber', width=1.3)
    return f, T('Subscription reads: a burst of 250, then 25 a second for as long as you keep going.',
                'Leituras da assinatura: uma rajada de 250, e depois 25 por segundo enquanto você continuar.')
