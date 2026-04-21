## Summary

<!-- One or two sentences on what this PR does and why. -->

## Changes

<!-- Bullet list of concrete changes. -->

-
-

## Test plan

<!-- How did you verify this works? Tick what you did. -->

- [ ] `zsh tests/run_tests.sh` green locally
- [ ] `zsh tests/run_self_tests.sh` green locally
- [ ] `zsh tests/run_stage3_tests.sh` green locally (if stage3 touched)
- [ ] `zsh tools/verify_manifest.sh` green (if templates touched)
- [ ] `zsh tests/cross_test.sh linux_x86_64` green (if runtime/codegen touched)
- [ ] `zsh tests/cross_test.sh linux_arm64` green (if runtime/codegen touched)
- [ ] New/updated test added for the change (TDD)

## Checklist

- [ ] Subject line ≤ 70 chars, imperative mood
- [ ] Body explains WHY
- [ ] No `**bold**` in markdown
- [ ] If test-first was skipped, reason documented in commit
- [ ] Ran pre-push hooks (not bypassed with `--no-verify`)

## Related

<!-- Issue numbers, prior PRs, external references. -->
