# SlimBrave Linux

SlimBrave Linux is a terminal tool to debloat Brave on Linux using managed policies.

It is inspired by the original SlimBrave PowerShell project and reworked for Linux with a simple interactive menu.

Original inspiration: https://github.com/ltx0101/SlimBrave

## Features

- Interactive menu with clear categories
- 3 adaptive ASCII banners (large, medium, compact)
- Colored terminal output using Brave palette accents (`#FB542B`, `#A0A1B2`)
- Quick presets: `max-privacy`, `balanced`, `performance`, `developer`, `parental`
- `balanced` is the recommended preset (default in preset menu)
- Manual toggle mode (option by option)
- Presets and manual toggles auto-apply immediately
- DNS over HTTPS mode control
- Backup, restore, and reset
- Writes a managed policy file to the active Brave Linux policy path

## Requirements

- Linux
- Brave installed
- `bash` (4+)
- `sudo` to write in `/etc/...`

## Install

```bash
git clone https://github.com/leo10m2010/SlimeBrave-Linux.git
cd SlimeBrave-Linux
chmod +x slimbrave.sh
./slimbrave.sh
```

## How it works

The script detects the active Brave Linux policy path and writes `slimbrave.json` there.
Known paths:

- `/etc/brave/policies/managed/slimbrave.json`
- `/etc/brave-browser/policies/managed/slimbrave.json`

## Verify

1. Pick a preset or toggle options in the script (auto-apply).
2. Restart Brave.
3. Open `brave://policy`.
4. Confirm policies are loaded.

Note: when you pick a preset or toggle a manual option, changes are written
immediately (no second apply step needed).

If policies do not appear, make sure Brave was fully closed and opened again.

## Safety

- The script only manages `slimbrave.json`.
- It creates backups in `backups/` before overwrite/reset when possible.
- You can restore any backup from the menu.

## Notes

- Some policies can affect browser functionality strongly (for example safe browsing or developer tools).
- If something breaks your workflow, use `Restore backup` or `Reset total`.

## Contributing

PRs and issues are welcome.

## License

MIT. See `LICENSE`.
