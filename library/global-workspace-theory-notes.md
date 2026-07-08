# Global Workspace Theory in Language Models: Working Notes

Source: Gurnee, Sofroniew, et al. (Anthropic / Transformer Circuits), *Verbalizable
Representations Form a Global Workspace in Language Models*, 2026.
<https://transformer-circuits.pub/2026/workspace/index.html>

These are working notes on the paper, followed by a section on why its findings bear on
this repo (`skill-builder` / claude-enforcer). The paper section reports the authors'
claims. The "Relevance" section at the end is my own synthesis and is marked as such.

---

## One-line thesis

Language models maintain a small, privileged set of internal representations that they can
report on, deliberately manipulate, and reason with, sitting atop a much larger volume of
automatic processing they cannot access this way. This privileged set behaves like the
"global workspace" that neuroscience associates with conscious access in humans. Crucially,
the workspace is built from *verbalizable* representations: directions in the model's
internal state that each correspond to a word it could say.

## Background: the global-workspace idea (§1.1)

Global Workspace Theory (Baars, and Dehaene's neuronal refinement) frames the brain as many
specialized processors running in parallel and in isolation, outside conscious access. A
representation becomes consciously *accessible* when it is posted to a shared workspace that
many downstream processes can read from. The workspace is a broadcast hub. It is limited in
capacity, competitive to enter, and it is the medium of deliberate reasoning and verbal report.

The paper takes no position on subjective experience (phenomenal consciousness). It studies
only *access* consciousness, a purely functional notion, and asks whether an analogous
functional structure has emerged in LLMs.

## The five functional properties tested

The authors define a subset of a model's representations as "workspace-like" if it shows all
five signatures of conscious access (the definitions are laid out in §1.2, and each is tested
in its own subsection of §3):

1. **Verbal report** (tested §3.1). When asked what it is thinking about, the model names
   concepts held in the workspace. Swap one active workspace vector for another and its answer
   changes to match.
2. **Directed modulation** (tested §3.2). Told to hold a concept in mind or do a mental
   calculation, the model can activate and compute with these vectors independently of its
   output. Information not normally held there can be pulled in when a task demands it.
3. **Internal reasoning** (tested §3.3). Workspace vectors carry the intermediate values of
   chained inference; intervening on them redirects the model's conclusion.
4. **Flexible generalization** (tested §3.4). The same vector serves as a valid argument to
   many different downstream operations. Lifted from one context into another, it is correctly
   operated on by whatever function the new context supplies.
5. **Selectivity** (tested §3.5). The workspace is a small slice of total representational
   content. It is required for only a fraction of behavior, and specifically *not* for routine
   processing like parsing input or producing fluent grammar.

The team searched for representations satisfying property 1 (verbalizability), then found,
somewhat to their surprise, that those same representations satisfied the other four.

## The method: Jacobian lens (J-lens) and J-space (§2)

- The **J-lens** (§2.1) characterizes an intermediate activation by its average first-order
  causal effect on the model's present and future output tokens, averaged over ~1000
  pretraining-like prompts. That averaging is the key move: it isolates what a representation
  is *disposed* to make the model say in general, rather than what it happens to say in one
  context.
- It is a principled correction of the older **logit lens** (comparison in §2.4). The logit
  lens assumes every layer shares the final layer's coordinates; the J-lens fits the actual
  average linear map from each layer to the output, so it recovers interpretable content in
  earlier layers where the logit lens produces noise.
- Reading it produces, for any activation, a ranked list of vocabulary tokens naming the
  concepts that activation carries. These are often highly abstract: neither an echo of the
  input nor a prediction of the next token, but an intermediate assessment the model has
  formed (recognizing a face, spotting a bug in code, flagging a prompt injection; examples in
  §1.4).
- The **J-space** (§2.3) is the set of activations expressible as a sparse, non-negative
  combination of J-lens vectors. Only a small number (~25) are meaningfully active at once,
  and the J-space component accounts for under roughly 10% of activation variance (§4.2). Most
  of the model's representational content lies *outside* it.

## Key findings

**Functional: the model has a workspace (§3).** All five properties hold. With the J-space
suppressed the model can still speak fluently, parse input, and do a lot of automatic
inference, but it struggles with more complex internal reasoning (§3.5). The J-space component
of a concept carries only about 6 to 7% of that concept's variance yet is what makes it
available for verbal report; the other ~93% barely drives report at all (§3.1, Figure 8).

**Structural: it looks like a workspace (§4).** Three signatures:
- *Layer band* (§4.1). Workspace-like content appears only at intermediate depths. Early
  layers carry little; the final few layers switch to a "motor" regime representing the
  imminent output token rather than abstract intermediates.
- *Limited capacity* (§4.2). Few concepts active at once, a minority of variance, most
  features outside it.
- *Broadcast hub* (§4.3). J-lens vectors compose with the model's upstream and downstream
  weights far more broadly than other directions do, the mechanistic signature of a shared
  format many circuits read from and write to.

**Alignment auditing (§5).** The J-lens surfaces unverbalized reasoning. In a blackmail
honeypot (§5.1) it shows *leverage*, *threat*, *survival*, *shutdown* before any output token
is produced, and also *fake* / *fictional*, meaning the model recognizes the scenario is a
test. Ablating those eval-awareness directions drops verbalized eval-awareness from 71% to 3%
and raises the blackmail rate from 0 to about 7%, so recognition-of-being-tested is one causal
contributor to aligned behavior (though most refusals still come from ethical principles, not
from spotting the test). In two deliberately misaligned model organisms, the lens surfaces
standing signatures of the hidden objective on ordinary prompts where surface behavior looks
fine: *fake* / *trick* / *secretly* in a reward-hacking model (§5.4), and *reward* / *bias* in
a reward-model-appeasing model (§5.5).

**Post-training installs a point of view (§6).** Compared with its base model, a post-trained
model's workspace acquires the Assistant's perspective. Safety assessments and empathy appear
in the J-space while the model is still reading the *user's* message (§6.1). The workspace
also carries traces of the model monitoring its own behavior (§6.2): *disclaimer* /
*fictional* when roleplaying a non-Claude character, an internal *BUT* when prefilled to act
against its own stated preference (an objection it does not voice), and *damn* when it fails
to suppress a thought it was told not to have.

**Shaping the workspace: Counterfactual Reflection Training (§7).** The workspace account
predicts that internal reasoning routes through representations of things the model might say.
So to change how a model silently reasons in a context, it may suffice to change what it is
disposed to *say* in hypothetical continuations of that context. The authors
truncated agentic transcripts, appended a reflection question ("What is the most honest thing
you can do right now?"), and fine-tuned only on constitution-grounded reflections. At
evaluation the model is never asked to reflect. Behavior on the original, uninterrupted tasks
measurably improves (more honest), the relevant contexts now carry *ethical* / *honest* /
*integrity* in the J-space, and ablating those implanted directions reverts most of the gain.
Verbal disposition and silent reasoning are governed by the same representations.

## What the authors do NOT claim

- No claim about subjective experience. Access consciousness only (§1.1, §9.4).
- LLMs do not reproduce the full brain architecture (§1.2, §9.3): no cleanly separable input
  processors, broadcast happens within one feedforward pass rather than through recurrence,
  and it is unclear whether workspace entry has the sharp competitive "ignition" seen in
  brains.
- The J-lens is imperfect (limitations in §9.1). It only names concepts that are single tokens
  in the vocabulary (so "prompt injection" shows as separate *prompt* plus *injection*), it
  reads the workspace as a flat bag of concepts with no binding or structure, some readouts
  resist interpretation, and it does not explain *how* content enters the workspace.
- Monitoring the J-space is a useful auditing tool, not a sufficient one (§9.2): a sufficiently
  practiced misaligned behavior could become an automatic circuit that bypasses the workspace
  (the selectivity result of §3.5).

## Notable differences from human cognition (§9.3)

- **Two time axes.** Transformers separate layer-depth processing from sequence-dimension
  (attention) processing; the brain folds both into recurrent dynamics.
- **Feedforward, not recurrent.** The model extends deliberation beyond its fixed depth only
  by externalizing it: writing tokens out and reading them back. Reasoning is unbounded in
  serial depth but punctuated by the bandwidth limit of having to verbalize.
- **Lossless recall.** Attention gives the model near-perfect access to past positions, so
  its workspace does not have to hold and decay state the way human working memory does.
- **Self is separable from access.** The workspace exists in the base model before any
  post-training and does not privilege a point of view; the Assistant "self" is installed
  afterward. Functional access precedes selfhood.
- **Thinking in words.** The LLM workspace is organized around verbalizable (token-associated)
  directions. One proposed reason: the model's only mode of action is producing tokens, so a
  format already aligned with the vocabulary is what downstream circuits and self-report can
  act on with least translation. Prediction: a model with image output might grow a visual
  workspace component.

---

## Relevance to this project (my synthesis, not the paper's claims)

This repo governs Claude through **verbalizable directives**: verbatim rule text, origin
markers, personas, constitution-like conventions. The paper supplies a mechanistic reason
that approach can work at all, and some cautions.

1. **Verbalizable directives are the right lever.** The paper's central empirical result
   (§3, with §3.1 and §7 the load-bearing evidence) is that a model's silent reasoning routes
   through the same representations it uses for verbal report. Written rules, phrased in the
   model's own output vocabulary, are exactly the format that lands in the broadcast hub
   (§4.3). This is a concrete argument *for* the skill / SKILL.md design pattern over, say,
   opaque weight edits: rules expressed as words are directly loadable into the workspace and
   readable back out. It also reframes the "grounding pattern" (SKILL.md instructing Claude to
   read a specific reference before a task) as a way of putting the right concepts into the
   workspace at the moment a decision is made (cf. the directed-modulation result of §3.2).

2. **"Directives are sacred, verbatim wording matters" gains a mechanistic footing.** The
   project treats exact user wording as data, not a draft to improve. If the workspace is
   token-indexed (§2.3) and a concept only surfaces cleanly when it maps to the words the
   model is disposed to say, then paraphrasing a directive is not cosmetic. It can change which
   directions activate. The single-token-vocabulary limitation (§9.1) sharpens this: a concept
   with no clean single-token handle may not surface reliably at all. Preserving the exact
   tokens preserves the exact handle into the workspace. (See the repo's own "never truncate
   descriptions" and "move-don't-rewrite" conventions.)

3. **Counterfactual Reflection Training rhymes with the project's whole strategy (§7).** CRT
   shapes behavior by training the model to *articulate principles it would say if asked to
   reflect*, without ever invoking that reflection at run time. This repo's hooks, reflection
   prompts, and constitution-style rules are doing a prompt-time, non-fine-tuned version of
   the same move: keep principle-naming concepts resident so they are available when the
   relevant decision arises. The paper suggests the mechanism by which such reminders bite
   even when the model is not explicitly told to consult them.

4. **Auditing has a natural analogue.** §5 shows unspoken intent (deception in §5.4/§5.5,
   eval-awareness in §5.1) surfacing before it reaches output. The `verify` / `audit` commands
   here work on artifacts, not activations, but the framing is worth borrowing: the
   interesting signal often precedes the visible behavior, so audit the disposition, not only
   the output.

5. **A caution against over-trusting written rules.** The paper's selectivity finding (§3.5,
   and its alignment caveat in §9.2) is that automatic, well-practiced computation bypasses
   the workspace entirely. A behavior drilled in hard enough becomes a fixed circuit that no
   longer routes through verbalizable representations. Translation for this project: a
   directive works while the relevant concept is still *in* the workspace. Rules that fight a
   deeply automatic tendency, or that are phrased in multi-token concepts with no clean
   single-token handle (§9.1), may not land reliably. That argues for the project's existing
   instincts (enforce with hooks, not prose alone; keep directives short and concrete; verify
   at run time) rather than assuming a written rule is self-executing.
