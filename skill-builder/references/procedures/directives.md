## Adding Directives Procedure

When user gives a new rule for an existing skill:

1. **Classify before placing** — Is this a directive or a guideline? A directive is a rule born from real experience: "never do X," "always do Y," a hard constraint that came from a specific failure or insight. A guideline is general approach advice. If the new content describes a rule the author learned the hard way, or a constraint that should never be skipped, it's a directive. Route it to the `## Directives` block at the top of the skill, not into a numbered guideline list. Do not wait for the user to ask whether it belongs there. If the skill already has a `## Directives` section, new directives go there immediately. If it doesn't have one yet and this is the first directive, create the section.
2. **Extract exact wording** — Quote their instruction verbatim
3. **Add to Directives section** — With date and source
4. **Run Post-Action Chain** — Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the affected skill. The chain's hooks display mode will detect enforceable patterns and recommend hooks or agents; the user can then choose to execute.

**Example conversation:**

User: "For my budget app, I never want you to use the Uncategorized account, ID 12345678"

Your action:
```markdown
## Directives

> **NEVER assign a transaction to Uncategorized (ID: 12345678).**
> If a transaction doesn't match a known category, stop and ask which category to use.

*— Added 2026-01-22, source: user instruction*
```

Then the Post-Action Chain runs a scoped review — the hooks display mode detects the specific ID `12345678` as a grep-block hook candidate, the agents display mode evaluates whether a Matcher agent applies, and the user is offered execution choices.
