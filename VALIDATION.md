# Local verification

Verified on macOS before publication.

- Fresh and repeat installation into a path containing spaces.
- Removal and repeated removal preserve other pets.
- Legacy update preserves registered directory and ID without a duplicate.
- Injected final-rename failure restores the original and releases the lock.
- Extra files in the Von directory survive removal.
- Modified managed files cause safe refusal.
- Corrupt package rejected before mutation.
- Symlink targets rejected.
- Duplicate current and legacy installations rejected.

ShellCheck and shfmt pass. The hatch-pet atlas validator passes.
The packaged sprite is byte-for-byte identical to the optimized installed asset.

These checks cover format and installation behavior. Live Codex rendering was
not observed during this packaging pass. Startup and hover behavior are not
claimed fixed.

## Windows and Linux scripts

The Linux Bash installer and uninstaller passed the same nine isolated smoke
checks on macOS with Python 3 and sha256sum. The unchanged macOS scripts also
passed all nine checks. ShellCheck and shell formatting checks passed.
Run `python3 tests/smoke.py linux` or `python3 tests/smoke.py macos` to repeat.

PowerShell scripts were reviewed but not executed: this host has no PowerShell
runtime. Native Windows/Linux execution and Codex rendering remain untested.
Windows requires PowerShell 5.1+; Linux requires Bash, Python 3 and sha256sum.
No scripts change the active pet selection or ChatGPT Work Pets.
