<!-- code-eval-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# Gotchas — quick WRONG/CORRECT reminders

Fast reference for the traps that bite most often. Full reasoning in
[guards.md](guards.md) and [cross-file-detection.md](cross-file-detection.md).

## Reference counting

```
# WRONG: substring match inflates the count
rg 'user'                 # matches userId, currentUser, user_name

# CORRECT: word boundary
rg -w 'user'
```

## "Zero references" ≠ "dead"

```
# WRONG: delete on a zero-reference grep
rg -wc 'handlePayment'    # → 1 (definition only) → delete?  NO.

# CORRECT: clear the guards first
#  - is it exported from a published package?      (library API = used)
#  - is it a route/handler/decorated/lifecycle fn? (framework-invoked = used)
#  - reflection/DI/serialization in scope?         (poisoned = no auto-delete)
#  - re-exported through a barrel?                 (trace the chain)
#  then: HIGH tier only → atomic remove → build + tests → revert on failure
```

## Comments and strings are not references

```
# A symbol named only in a // comment, docstring, or log string is NOT a use.
# If every match is in a comment/string → treat as zero → but still LOW tier.
```

## Defer to the compiler

```
# WRONG: trust grep over the type system
# CORRECT: if `tsc`/`cargo`/`go build`/`mypy` exists, it is the source of truth.
#          grep only proposes candidates.
```

## Duplication: don't over-DRY

```
# WRONG: extract a shared helper at the first 2 look-alike blocks
# CORRECT: rule of three — extract when ≥3 copies of ONE concept must change
#          together. Leave coincidental similarity and test duplication.
```

## Scope discipline (auto-fix)

```
# WRONG: while fixing dead code, also "tidy" unrelated files
# CORRECT: one logical deletion per commit; never broaden the diff beyond the
#          finding. Report extra opportunities; don't act on them.
```

## Dynamic languages have no safety net

```
# Python / JS / Lua / Bash: no compile step catches a wrong deletion.
# Require an extra confirmation tier; prefer report-only.
```

## Generated and vendored code

```
# WRONG: delete a symbol in *.pb.go / dist/ / node_modules/
# CORRECT: never edit generated/vendored output (honor "DO NOT EDIT"); fix the
#          generator. Still COUNT references found there.
```
