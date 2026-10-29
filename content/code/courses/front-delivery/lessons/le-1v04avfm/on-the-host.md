---
title: Where the values come from on a host
version: 1
---

**On a host that builds for you, the variables come from its dashboard, set per environment, and reach
the build as ordinary environment variables.** That is why the shell beats every `.env` file: a value
typed into the dashboard overrides whatever the repository says, without anybody editing a file.
**Nothing in this section was run for this course**; it is what each host's documentation described in
October 2026.

## Per host

All three hosts with previews let one variable have a different value for production and for previews:

- **Vercel**: Project Settings, then Environment Variables. Each value is ticked for Production, Preview,
  Development or any mix. `npx vercel env pull` writes the development values into a local file, which
  is a `.local` file for the reason the last section of this lesson gives.
- **Netlify**: the site's configuration, under Environment variables, where a value can differ per
  **deploy context**: production, deploy previews, branch deploys. A value that is not secret can live
  in `netlify.toml` instead, where it is reviewed with the code:

```toml
[context.deploy-preview.environment]
  VITE_TITLE = "Study planner (preview)"
```

- **Cloudflare Pages**: the project's Settings, under Variables and Secrets, with a Production and a
  Preview environment.
- **GitHub Pages** has no settings of its own for this; the workflow builds, so the workflow supplies the
  values, from the repository's **Settings, Secrets and variables, Actions**.

## In a workflow

GitHub Actions keeps two kinds of value. **Variables** are plain configuration, readable as `vars.NAME`.
**Secrets** are encrypted, readable as `secrets.NAME`, and masked as `***` if a step prints one. A step
receives either through its `env:`:

```yaml
      - name: Build
        run: npm run build
        env:
          VITE_TITLE: ${{ vars.SITE_TITLE }}
      - name: Deploy
        run: npx wrangler pages deploy dist
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

Look at which step gets which. **The build gets the title, which the page shows. The deploy gets the
token, which the page must never have.** The token has no `VITE_` prefix, and it is given only to the
step that uploads, so it cannot reach the bundle by either route. That is the prefix and the secret store
working together, and it is the shape every pipeline in lesson 3 keeps.

Two details GitHub documents and that surprise people. A workflow started by a **pull request from a
fork** does not receive the repository's secrets, so a stranger's pull request cannot print them; a
preview that needs a secret simply fails there. And masking hides a secret only when it appears exactly
as stored: a secret that a step transforms, encodes or splits is printed in the clear.

## Previews get their own values

A preview build is public at its own address, and **a preview should never hold a production value
that matters**: not the production API, not a key with production's limits. Give previews the staging
values, which is what the per-environment settings above exist for. Lesson 3 comes back to it, because a
preview is the easiest place for production data to leak.
