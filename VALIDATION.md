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
