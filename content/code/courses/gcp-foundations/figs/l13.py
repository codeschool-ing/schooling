"""Lesson 13: reading the bill."""
from figures import Fig, T, figure


@figure('l13-discounts', 13)
def discounts():
    f = Fig('l13-discounts', 720, 250, T(
        'One hour of the planner\'s eligible Compute Engine usage in São Paulo, drawn as a bar of 48 '
        'vCPUs, consumed from left to right in the order Google applies discounts. The first 32 vCPUs '
        'are covered by a resource-based commitment. The next part is covered by a flexible commitment, '
        'as far as its dollars an hour reach. What is left is charged at the on-demand price, and only '
        'that part may then earn a sustained use discount. No vCPU receives two discounts.',
        'Uma hora do uso elegível do Compute Engine do planner em São Paulo, desenhada como uma barra de 48 '
        'vCPUs, consumida da esquerda para a direita na ordem em que o Google aplica os descontos. As '
        'primeiras 32 vCPUs são cobertas por um compromisso baseado em recursos. A parte seguinte é coberta '
        'por um compromisso flexível, até onde os dólares por hora dele alcançam. O que sobra é cobrado pelo '
        'preço sob demanda, e só essa parte pode depois ganhar o desconto por uso contínuo. Nenhuma vCPU '
        'recebe dois descontos.'))
    x0, x1 = 40, 680
    w = (x1 - x0) / 48
    f.text(360, 22, T('one hour, 48 vCPUs of eligible usage', 'uma hora, 48 vCPUs de uso elegível'), size=10.5)
    parts = [(0, 32, '--phosphor', T('1. resource-based', '1. baseado em recursos'),
              T('32 vCPUs committed', '32 vCPUs comprometidas')),
             (32, 40, '--amber', T('2. flexible', '2. flexível'), T('its dollars an hour', 'seus dólares por hora')),
             (40, 48, '--wire', T('3. on demand', '3. sob demanda'), T('may earn sustained use', 'pode ganhar uso contínuo'))]
    for a, b, colour, name, note in parts:
        xa, xb = x0 + a * w, x0 + b * w
        f.rect(xa, 50, xb - xa, 56, stroke=colour, fill='--panel', width=1.6, rx=2)
        f.text((xa + xb) / 2, 136, name, size=10, fill='--paper' if colour == '--wire' else colour)
        f.text((xa + xb) / 2, 154, note, size=9, fill='--paper-dim')
    for v in (0, 32, 40, 48):
        f.text(x0 + v * w, 120, str(v), size=9, mono=True, fill='--paper-dim')
    f.arrow([(x0, 190), (x1, 190)], stroke='--paper-dim')
    f.text(360, 210, T('each layer covers what the one before it left', 'cada camada cobre o que a anterior deixou'),
           size=10)
    f.text(360, 230, T('no vCPU is discounted twice', 'nenhuma vCPU recebe dois descontos'), size=9.5,
           fill='--paper-dim')
    return f, T('Discounts are applied in turn, never stacked.',
                'Os descontos são aplicados em sequência, nunca somados.')
