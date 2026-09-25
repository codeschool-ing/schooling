---
title: Windows: a list rather than three questions
version: 1
---

NTFS, lesson 2's file system, does not have owner, group and others. **Every file and folder carries an
access control list**, an *ACL*: a list of entries, each naming a user or group, whether it is
*allowed* or *denied*, and what.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The access control list of a Windows folder, D:\\Accounts, as its Security tab shows it, one row per entry. SYSTEM, allow, full control, inherited from D:. Administrators, allow, full control, inherited from D:. The OFFICE Accounts group, allow, modify, set on this folder. The OFFICE Interns group, deny, read, set on this folder.\"><defs><marker id=\"ac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">D:\\Accounts, Security tab: an access control list</text><text x=\"26\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">who</text><text x=\"206\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">allow / deny</text><text x=\"336\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what</text><text x=\"476\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from</text><rect x=\"20\" y=\"54\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SYSTEM</text><text x=\"206\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Allow</text><text x=\"336\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Full control</text><text x=\"476\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inherited from D:\\</text><rect x=\"20\" y=\"90\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Administrators</text><text x=\"206\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Allow</text><text x=\"336\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Full control</text><text x=\"476\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inherited from D:\\</text><rect x=\"20\" y=\"126\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OFFICE\\Accounts</text><text x=\"206\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Allow</text><text x=\"336\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Modify</text><text x=\"476\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">this folder</text><rect x=\"20\" y=\"162\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OFFICE\\Interns</text><text x=\"206\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Deny</text><text x=\"336\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Read</text><text x=\"476\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">this folder</text></svg>", "caption": "Not three fixed questions but a list, as long as it needs to be, naming any user or group. Entries flow down from the parent folder unless inheritance is turned off."}
```

The permissions an entry can grant come in a few standard bundles:

| permission | allows |
|---|---|
| **Full control** | everything, including changing the permissions themselves |
| **Modify** | read, write, create and delete |
| **Read & execute** | open files and run programs |
| **Read** | open files and list folders |
| **Write** | create files and change them |

Three rules decide what a person actually gets:

1. **Entries add up.** A user in two groups gets both groups' permissions.
2. **Deny beats allow**, when both are set in the same place. That is how the drawing keeps the interns
   out even if they are also in a group allowed to read. Deny entries are powerful and hard to reason
   about, so they are used sparingly.
3. **Entries are inherited** from the folder above unless inheritance is turned off. An entry set
   directly on a folder beats an inherited one.

The *Security* tab's **Advanced > Effective Access** answers the only question that matters in a
ticket: given all the entries, what can *this* person do here?

Over the network there is a second list, the **share permissions** of the shared folder. **A user gets
the more restrictive of the two**, which is why a common arrangement is to share with *Everyone: Full
control* at the share and do all the real work in the NTFS list.

```sh
icacls D:\Accounts                                        # list the entries
icacls D:\Accounts /grant "OFFICE\Accounts:(OI)(CI)M"    # Modify, passed down to files and folders
icacls D:\Accounts /remove "OFFICE\Interns"              # take an entry away
Get-Acl D:\Accounts | Format-List                         # the same list, as an object
```

**None of those were run for this lesson.** `(OI)(CI)` means the entry passes down to files (*object
inherit*) and subfolders (*container inherit*), and `M` is Modify. PowerShell's `Get-Acl` reads the same
list on Windows. On Linux it does not exist:

```
PS /srv/office> Get-Acl payroll.txt
Get-Acl: The term 'Get-Acl' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
```
