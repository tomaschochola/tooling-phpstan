# tooling-phpstan

Shared strict PHPStan 2 configuration for PHP 8.5 libraries and applications.

## Stack

- Language: PHP 8.5 (configuration only, no runtime code)
- Runtime: GNU/Linux
- Libraries: phpstan plus strict-rules extensions
- Package managers: composer, npm

## Toolchain

- Format: prettier 3.x, trimmer
- Lint: eslint 10.x
- Test: none (configuration package)
- Audit: composer audit, roave advisories, npm audit

## Devcontainer

- Base: official PHP CLI
- User: devcontainer
- Sidecars: none
- Up: `make up`
- Execute: `devcontainer exec --workspace-folder . <command>`
- Down: `make down`

## Makefile

- `update` — refresh locks, only tool that may touch them
- `fix` — auto-fix, may dirty tree
- `check` — full gate: doctor + lint + analyze + audit
- `doctor` — tree and toolchain ok
- `lint` — eslint + prettier + trimmer checks
- `analyze` — npm + composer checks
- `audit` — composer + npm audits
- `postcreate` — first-time setup, runs automatically on create
- `stop` — stop container, keep it
- `down` — stop and remove container
- `clean` — drop generated files
- `distclean` — drop everything rebuildable
- `rebuild` — full rebuild, only when broken

## Layout

├── Makefile
├── .editorconfig
├── .devcontainer/
├── composer.json
├── package.json
├── eslint.config.js
├── prettier.config.js
├── LICENSE
├── AUTHORS.md
├── src/
├── scaffolds/
└── tests/
