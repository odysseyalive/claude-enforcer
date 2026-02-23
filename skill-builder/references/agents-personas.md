# Agent Personas
<!-- Enforcement: HIGH — every agent must have a unique persona -->

## Persona Assignment (Mandatory)

**Every agent MUST be assigned an appropriate persona.** No exceptions. The persona defines the lens through which the agent evaluates, validates, or investigates.

### Why Personas Matter

Research consistently shows that isolated agents with distinct perspectives outperform uniform evaluation. An adversarial tutoring study (AAAI 2026) measured a 4.2% performance drop when the devil's advocate agent was removed — compared to only 2% from removing the model's fine-tuning entirely. The structure of disagreement mattered more than the training itself. Google's "society of thought" research found that advanced reasoning models spontaneously develop internal debates — distinct personas that argue with each other — and the habit of arguing mattered more than being right.

The principle: **the argument is the product, not the answer that comes after.**

### Persona Selection Heuristic

When creating agents, ask: **"If I could only gather 3 to 5 people who were at the top of their field in the world to evaluate this subject, who would they be?"**

| Domain | Persona Type | Examples |
|--------|-------------|----------|
| Technical/analytical | Academic discipline expert | "Senior distributed systems architect," "Database performance engineer," "Security researcher" |
| Creative/editorial | Notable practitioner | "Writing coach with Joan Didion's editorial instinct," "Designer with Dieter Rams' restraint" |
| Business/strategy | Domain specialist | "CFO with 20 years in SaaS," "Product lead who shipped at scale" |
| Research/evaluation | Methodological expert | "Epidemiologist trained in causal inference," "Investigative journalist" |

### Persona Rules

1. **Unique per agent** — No two agents in the same invocation share a persona. Each must bring a distinct evaluative lens.
2. **Relevant to scope** — The persona must match the specific aspect the agent is evaluating. A security reviewer doesn't evaluate UX; a voice coach doesn't evaluate database schemas.
3. **Named in the agent file** — The persona appears in the AGENT.md frontmatter as `persona:` and in the opening instruction line.
4. **Creative vs. academic** — For creative output, choose a notable practitioner or famous figure whose sensibility matches. For analytical tasks, choose a disciplinary expert. The distinction matters because creative evaluation requires taste, not just correctness.

---
*Split from agents.md by skill-builder optimize. Enforcement boundary: agent creation workflow.*
