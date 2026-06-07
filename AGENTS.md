# AGENTS.md

## Project

`gwbc` — a Nix flake that clones a git repo into a bare-repo + worktree layout (`<name>/.git` + `<name>/<default-branch>`).

## Structure

The entire application is inlined Bash inside `flake.nix`. There are no external scripts, modules, or test files.

## Commands

```bash
nix build          # build; output at ./result/bin/gwbc
nix run . -- <url> [dir]   # build + run
nix flake check    # validate flake structure
nix flake update   # update nixpkgs lock
```

There is no test suite, no formatter config, and no CI.

## Key quirks

- **Implicit shellcheck**: `pkgs.writeShellApplication` runs `shellcheck` on the embedded script at build time. A build failure may be a lint error, not a runtime bug.
- **Nix string escaping**: Inside the `'' ... ''` block in `flake.nix`, Bash `${var}` must be written as `''${var}` to avoid Nix interpolation. Nix-level interpolation uses bare `${expr}` (e.g., `${scriptName}`).
- **No devShell**: `nix develop` is not configured. Edit `flake.nix` directly and iterate with `nix build` / `nix run`.
