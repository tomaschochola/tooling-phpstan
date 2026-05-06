# Design

This package exposes explicit PHPStan target configurations.

`php_85_library.neon` is the strict PHP 8.5 library contract.
`php_85_project.neon` is the strict PHP 8.5 project contract.

These files are intentionally duplicated where duplication improves direct auditability.
Do not introduce a shared hidden default file unless a future change proves that duplication is causing correctness defects.
