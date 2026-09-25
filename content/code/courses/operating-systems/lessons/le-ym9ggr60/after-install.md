---
title: Six things before anybody uses it
version: 1
---

The desktop appearing is not the end. A new installation needs six things before it goes to its user,
and doing them in this order saves restarts:

1. **Windows Update, until there is nothing left.** The installer's copy of Windows is weeks or months
   old. *Settings > Windows Update > Check for updates*, install, restart, and check again: it usually
   takes two or three rounds.
2. **Drivers.** Windows Update brings most of them. For the rest, the maker's support site, found by the
   **model number** on the sticker. Device Manager (lesson 1) should show no yellow triangles when you
   are done.
3. **Activation.** *Settings > System > Activation* should say *Windows is activated*. If it does not,
   fix it now; an unactivated Windows nags the user and restricts personalisation.
4. **Encryption, and where its key is.** Most new computers turn on **device encryption** or
   **BitLocker** by themselves. The disk can then be read only with the computer's TPM or with a
   48-digit **recovery key**, which Windows saves to the account from the last section. **Find out
   where that key is before the computer leaves your desk.** A firmware update or a motherboard repair
   can make Windows ask for it, and without it the data on the disk is gone for good.
5. **A standard account for daily use.** The account created during setup is an administrator. The
   person using the computer every day should use an account without administrator rights, which is
   lesson 10's subject.
6. **The office's software.** Lesson 11 covers installing it, from the store, from installers and from
   `winget`.

## Writing it down

For each machine, a line in a shared document: name, model, serial number, Windows edition and
version, where the recovery key is, who uses it. It takes two minutes. It is the list you will want the
day a computer is stolen, or when somebody asks how many machines still need upgrading.
