"""Lesson 21 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-wp4t71xc"
f = Fig("l21-chain", 720, 300,
        "The chain of trust behind a signing certificate, drawn top to bottom. At the top, Apple's root certificate, built into every Apple device. It signs the Worldwide Developer Relations intermediate certificate. That signs your Apple Development certificate, which holds your public key and your name. Your private key stays on your Mac, outside the chain, and signs the app. A device checks the app's signature against your certificate and walks up the chain to the root it already trusts. A Mac missing the intermediate cannot complete the walk.",
        "A cadeia de confiança atrás de um certificado de assinatura, desenhada de cima para baixo. No topo, o certificado raiz da Apple, embutido em todo aparelho Apple. Ele assina o certificado intermediário Worldwide Developer Relations. Esse assina o seu certificado Apple Development, que guarda a sua chave pública e o seu nome. A sua chave privada fica no seu Mac, fora da cadeia, e assina o app. Um aparelho confere a assinatura do app contra o seu certificado e sobe a cadeia até a raiz em que já confia. Um Mac sem o intermediário não completa a subida.")
rows = [(20, "Apple Root CA", "built into every device", "embutido em todo aparelho", "phosphor"),
        (110, "Apple WWDR intermediate", "the link people forget", "o elo que as pessoas esquecem", "amber"),
        (200, "Apple Development: you", "your public key and name", "a sua chave pública e o seu nome", "wire")]
for y, name, en, pt, col in rows:
    f.box(40, y, 300, 60, stroke=col)
    f.text(190, y + 22, name, mono=True, size=11, fill="paper", weight="600")
    f.text(190, y + 42, en, pt, size=10, fill="paper-dim")
f.line(190, 80, 190, 108, color="phosphor")
f.text(240, 95, "signs", "assina", size=10, fill="paper-dim")
f.line(190, 170, 190, 198, color="amber")
f.text(240, 185, "signs", "assina", size=10, fill="paper-dim")
f.box(430, 200, 260, 60, stroke="amber", fill="ink", dashed=True)
f.text(560, 222, "your private key", "a sua chave privada", size=11, fill="amber", weight="600")
f.text(560, 242, "on your Mac, never sent", "no seu Mac, nunca enviada", size=10, fill="paper-dim")
f.box(430, 60, 260, 60, stroke="wire")
f.text(560, 82, "Planner.app", mono=True, size=11, fill="paper", weight="600")
f.text(560, 102, "signed, every file", "assinado, cada arquivo", size=10, fill="paper-dim")
f.line(560, 198, 560, 122, color="amber")
f.text(608, 160, "signs the app", "assina o app", size=10, fill="paper-dim")
f.path("M428 90 C 380 90, 370 225, 342 228", color="paper-dim", dashed=True)
f.text(388, 150, "checked against", "conferido contra", size=10, fill="paper-dim")
f.write(lesson(L, "certificates"),
        "A device trusts the root and walks down to your certificate; your private key signs and is never part of the chain.",
        "Um aparelho confia na raiz e desce até o seu certificado; a sua chave privada assina e nunca faz parte da cadeia.")
