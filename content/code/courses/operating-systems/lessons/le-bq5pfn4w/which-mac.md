---
title: Which Mac, which macOS
version: 1
---

**Apple makes the hardware and the system together**, so the question "can this computer run it?"
has a shorter answer than on Windows: each macOS release names the Mac models it supports, and a Mac
either is on the list or is not. There is no TPM to switch on and no processor list to read.

What does matter is **which kind of chip** is inside, because it changes how the Mac starts, how you
reach its repair tools, and how long it will be supported.

| | Apple silicon | Intel |
|---|---|---|
| sold | since late 2020 (M1, M2, M3 and later) | 2006 to 2023 |
| how to tell | *About This Mac* says **Chip** | *About This Mac* says **Processor** |
| reaching Recovery | hold the **power button** | hold **Command-R** at start |
| last macOS | still current | **macOS Tahoe 26**, Apple has said |

Apple has said that macOS Tahoe 26, from 2025, is the **last release for Intel Macs**. An Intel Mac
keeps working after that, and gets security updates for a while, but a Mac bought in 2019 is closer to
the end of its support than its age suggests.

## Names and numbers

Each release has a name and a number: Sonoma was 14, Sequoia 15. From 2025 the number follows the
year, so the release after Sequoia is **Tahoe 26**, not 16. Support tickets, app requirements and
Apple's own documents all use both, and the number is the one to compare.

The menu bar's Apple menu, **About This Mac**, shows the chip, the memory and the version. The same
facts, as text, come from Terminal:

```sh
sw_vers                                  # ProductName, ProductVersion, BuildVersion
uname -m                                 # arm64 on Apple silicon, x86_64 on Intel
system_profiler SPHardwareDataType       # model, chip, memory, serial number
```

**None of these were run for this lesson.** They are macOS commands, and the machine this course's
transcripts come from is Linux. `uname` is the one you already know from lesson 1, and on a Mac it
prints `arm64` or `x86_64` depending on the chip.

## Before touching anything

The same three questions as lesson 2, with one more:

1. **The data.** Anything on the Mac that matters is copied somewhere else first, with **Time
   Machine** to an external disk or by copying the folders.
2. **The Apple Account.** Whose is it signed into? Write the answer down; it decides section 04.
3. **The model.** Apple silicon or Intel, and which macOS the model supports.
4. **The licence.** There is none to worry about. macOS comes with the Mac and reinstalling it is
   free.
