# Updating llamafile

Astro pins the llamafile runtime version in [`.llamafile-version`](./.llamafile-version).
The [`check-llamafile-update`](./.github/workflows/check-llamafile-update.yml)
workflow runs weekly (and on demand) and opens a GitHub issue whenever the
upstream [mozilla-ai/llamafile](https://github.com/mozilla-ai/llamafile)
project publishes a newer release than the pinned version.

The workflow only **notifies** — it can't update the binary itself, because
the binary lives on the USB drive (and isn't committed to the repo). When you
get a notification, do the swap manually with the steps below.

## When you get a "new release" issue

1. **Download** the new `llamafile` binary from the latest release:
   https://github.com/mozilla-ai/llamafile/releases/latest

2. **Replace it on the drive** (adjust the drive path if yours differs):
   ```bash
   cp ~/Downloads/llamafile /Volumes/ASTRO/ASTRO/bin/llamafile
   cp /Volumes/ASTRO/ASTRO/bin/llamafile /Volumes/ASTRO/ASTRO/bin/llamafile.exe
   chmod +x /Volumes/ASTRO/ASTRO/bin/llamafile
   xattr -d com.apple.quarantine /Volumes/ASTRO/ASTRO/bin/llamafile 2>/dev/null || true
   ```

3. **Verify it launches** and reports the new version:
   ```bash
   cd /Volumes/ASTRO/ASTRO
   ./bin/llamafile --version
   ```

4. **Skim the release notes** for that version. llamafile occasionally changes
   CLI flags or drops support for older model/quant formats between releases
   (e.g. the v0.10.0 build-system change). If `run.sh` ever errors on a flag
   after an update, that's the first place to check.

5. **Bump the version pin and commit**, so the update checker goes quiet until
   the next release:
   ```bash
   echo "NEW_VERSION_HERE" > .llamafile-version    # e.g. 0.10.4
   git add .llamafile-version
   git commit -m "Update llamafile to NEW_VERSION_HERE"
   git push
   ```

6. **Close the GitHub issue** the workflow opened.

## Notes

- Pushing changes under `.github/workflows/` requires a Personal Access Token
  with the **`workflow`** scope (classic token: `repo` + `workflow`). A token
  without it will be rejected on push. This only matters if you edit the
  workflow file — routine `.llamafile-version` bumps don't need it.
- The workflow won't open duplicate issues for the same version, so if you
  don't update right away it won't spam you.
- Optional Telegram alerts: add `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`
  under **Settings > Secrets and variables > Actions**. Without them, you just
  get the GitHub issue + email.
