---
title: The families, and what each one pairs
version: 1
---

It is tempting to read the families as tiers, as if `E` were a better `D` and `M` the best of
all, and to pick the highest one the budget allows. **A family is a ratio, not a rank.** Each one
pairs processor with memory, and sometimes with local disks or a GPU, in a proportion that suits
one kind of work. The right size is the one where the resource your program runs out of first is
the resource you are paying for most of.

## Six types and the families in them

Microsoft sorts its families into types by the work they are meant for. These are the current
ones, from the sizes overview read on 2026-10-30:

| type | families | what it is for |
| --- | --- | --- |
| general purpose | `A`, `B`, `D`, `DC` | web and application servers, small and medium databases, most things when you have no reason to choose |
| compute optimised | `F`, `FX` | work that keeps the processor busy: batch jobs, application servers, simulation |
| memory optimised | `E`, `Eb`, `EC`, `M` | relational databases, large caches, analytics that hold their data in memory |
| storage optimised | `L` | databases that read and write their own local NVMe disks at very high rates |
| GPU accelerated | `NC`, `ND`, `NG`, `NV` | training and running models, rendering, virtual desktops |
| high performance compute | `HB`, `HC`, `HX` | fluid dynamics, weather models, chip design |

Inside general purpose, `A` is the entry-level family and `B` is burstable, the subject of this
lesson's last section. `DC` is `D` with confidential computing, which uses hardware in the
processor to protect the machine's data while it is in use. `Eb` is `E` with more bandwidth to remote disks, and
`EC` is `E` made confidential. There is also an FPGA family, `NP`, which nothing in this course
needs.

## The ratio, measured

Divide memory by vCPUs and each family lands on a number. A `Standard_D2s_v6` has 2 vCPUs and
8 GiB, which is 4 GiB per vCPU; a `Standard_E2s_v6` has 2 vCPUs and 16 GiB, which is 8. An `M`
goes much further: `Standard_M8ms` has 218.75 GiB on 8 vCPUs, about 27 for each. The letters `l`,
`m` and `t` move a series along the same line, so `Standard_D2ls_v6` has 4 GiB for its two vCPUs,
2 per vCPU, half what the plain `D` carries.

```schooling-figure
{"svg": "<svg id=\"fig-family-ratio\" viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Memory per vCPU for current series of six families, on a scale where each step doubles, from 0.5 to 32 GiB. B: Bts_v2 at 0.5, Bls_v2 at 2, Bs_v2 at 4. D: Dls_v6 at 2, Ds_v6 at 4. F: Fals_v6 at 2, Fas_v6 at 4, Fams_v6 at 8. E: Es_v6 at 8. L: Ls_v3 at 8, with local NVMe disks. M: M8ms at about 27.\"><line x1=\"250.0\" y1=\"20\" x2=\"250.0\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"250.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><line x1=\"323.3\" y1=\"20\" x2=\"323.3\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"323.3\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><line x1=\"396.7\" y1=\"20\" x2=\"396.7\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"396.7\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><line x1=\"470.0\" y1=\"20\" x2=\"470.0\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"470.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><line x1=\"543.3\" y1=\"20\" x2=\"543.3\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"543.3\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><line x1=\"616.7\" y1=\"20\" x2=\"616.7\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"616.7\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">16</text><line x1=\"690.0\" y1=\"20\" x2=\"690.0\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"690.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">32</text><line x1=\"240\" y1=\"268\" x2=\"700\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"470.0\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">GiB of memory per vCPU, and every step to the right doubles it</text><rect x=\"16\" y=\"31\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">B</text><text x=\"56\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">burstable</text><line x1=\"250.0\" y1=\"46\" x2=\"470.0\" y2=\"46\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></line><circle cx=\"250.0\" cy=\"46\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"250.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bts_v2</text><circle cx=\"396.7\" cy=\"46\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"396.7\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bls_v2</text><circle cx=\"470.0\" cy=\"46\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bs_v2</text><rect x=\"16\" y=\"71\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">D</text><text x=\"56\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">general purpose</text><line x1=\"396.7\" y1=\"86\" x2=\"470.0\" y2=\"86\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></line><circle cx=\"396.7\" cy=\"86\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"396.7\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dls_v6</text><circle cx=\"470.0\" cy=\"86\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ds_v6</text><rect x=\"16\" y=\"111\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">F</text><text x=\"56\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">compute optimised</text><line x1=\"396.7\" y1=\"126\" x2=\"543.3\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></line><circle cx=\"396.7\" cy=\"126\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"396.7\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fals_v6</text><circle cx=\"470.0\" cy=\"126\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fas_v6</text><circle cx=\"543.3\" cy=\"126\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"543.3\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fams_v6</text><rect x=\"16\" y=\"151\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">E</text><text x=\"56\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">memory optimised</text><circle cx=\"543.3\" cy=\"166\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"543.3\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Es_v6</text><rect x=\"16\" y=\"191\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">L</text><text x=\"56\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">storage optimised</text><circle cx=\"543.3\" cy=\"206\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"543.3\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ls_v3</text><text x=\"555.3\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">+ NVMe</text><rect x=\"16\" y=\"231\" width=\"214\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--phosphor)\" font-weight=\"600\">M</text><text x=\"56\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the largest memory</text><circle cx=\"673.4\" cy=\"246\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"673.4\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M8ms</text></svg>", "caption": "A family sets where a series sits on this line, and the letters l, m and t move it along. F is the exception worth knowing: on v6 it does not sell less memory than D, it sells a whole core per vCPU."}
```

`L` sits at 8 GiB per vCPU like `E`, and what it adds is disks: a `Standard_L8s_v3` carries one
1.92 TB NVMe device in the host for every 8 vCPUs. Lesson 3 is about why a disk inside the host is
fast and why it is not where your only copy of anything should live.

**`F` is not the family with less memory**, which is the belief to drop if you arrive from a
platform where it was. On version 6 the compute-optimised family comes at all three ratios,
`Fals_v6` at 2, `Fas_v6` at 4 and `Fams_v6` at 8 GiB per vCPU. What it sells instead is the
processor: the Fasv6 series runs without simultaneous multithreading, so each vCPU is a whole
physical core rather than one of two threads sharing it. A `Standard_D2s_v5` on Intel is two
threads that share one core. A `Standard_F2as_v6` is two cores.

## Generations, and which processor

The current generations are v6 and v7, and each comes with a choice of processor that the name
spells out:

- **Intel**, no letter: `Dsv6` on fifth-generation Xeon (Emerald Rapids), `Dsv7` on Xeon 6
  (Granite Rapids).
- **AMD**, `a`: `Dasv6` on fourth-generation EPYC, `Dasv7` on fifth-generation EPYC.
- **Arm**, `p`: `Dpsv6`, `Dpdsv6` and `Epsv6` on Cobalt 100, the Arm processor Microsoft designs.
  The older `Dpsv5` and the burstable `Bpsv2` use Ampere Altra, which is Arm from another maker.

The Arm sizes carry two consequences. Cobalt 100 gives each vCPU an entire physical core, like
`Fasv6`, so two vCPUs are more processor than two Intel threads. And an Arm processor runs only
programs built for Arm, so the image the machine starts from has to be an `arm64` one. The shop's
order API is a Python program, and Python and most Linux distributions publish both builds; a
vendor's closed binary or a native library nobody compiled for `arm64` is where the move stops.
Lesson 2 is where the image is chosen, and where that pairing is checked.

## What the compiler knows about a size

A size is a property of a virtual machine resource, `hardwareProfile.vmSize`. Here is the shop's
order API declared as a machine, with only the part this lesson is about. A real machine also
needs an image (lesson 2), a disk (lesson 3) and a network interface (`azure-foundations`
lesson 16), so this declaration would not be enough to create one. Save it as `vm.bicep`:

```bicep
// vm.bicep
param location string = 'brazilsouth'

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-api'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ps_v6'
    }
  }
}
```

It compiles with nothing to say. Now change the size to `Standard_D3ps_v6`, which does not exist:
the series goes from two vCPUs to four, and there is no three. Then change it to the number `2`:

```
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ grep vmSize vm.bicep
      vmSize: 'Standard_D3ps_v6'
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ grep vmSize vm.bicep
      vmSize: 2
ana@laptop:~/azure$ bicep build vm.bicep
/home/ana/azure/vm.bicep(9,15) : Warning BCP036: The property "vmSize" expected a value of type "null | string" but the provided value is of type "2". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**The size that does not exist compiled cleanly.** The number was refused, because the type
Microsoft publishes for `vmSize` in this API version is `null | string`: any text at all. The
compiler knows that a size is a string and has no list of the strings that are sizes, so a typo
in a size name is one of the mistakes it cannot catch for you.

The command that knows is `az vm list-skus`, which asks Azure for the sizes a region offers and
which of them your subscription may use. Here it gets the answer you met in the first section:

```
ana@laptop:~/azure$ az vm list-skus --size Standard_D2ps_v6 --output table
ERROR: Please run 'az login' to setup account.
```

Against a real subscription the same command lists each matching size with the zones it is
offered in and any restriction on your subscription; it was not run in this course. **Which sizes
exist in `brazilsouth` is a question only Azure answers**, and it is the reason to run that command
before writing a size into a template rather than after the deployment fails.

## Choosing by what runs out first

Every program exhausts one resource first, and the family is chosen by that resource. Two of the
shop's own:

**The order API** answers small JSON requests and holds almost nothing in memory. Two vCPUs are
plenty and 4 GiB is more than it uses, so a `D2ls_v6` fits it with room to spare, and so would a
`D2ps_v6` once its image is built for Arm.

**The nightly sales report** loads the day's orders into memory and sums them, and it needs about
12 GiB and one busy vCPU. The general-purpose size that holds 12 GiB is a `D4s_v6`: 16 GiB, and
four vCPUs of which three sit idle. An `E2s_v6` has the same 16 GiB with two vCPUs. For the same
memory you are paying for half the processors, and for every copy of the job you run.

None of this is visible from outside the program. Its memory and processor use come from measuring
it under real load, which on Azure is Azure Monitor, and `azure-operations` lessons 8 to 13 set
that up. With nothing measured yet, start on a current general-purpose size and treat it as a
guess: resizing a machine restarts it on the new size, `az vm resize`, and lesson 4 makes
replacing machines routine.
