<!-- creative-scrub-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# Portable AI-Text-Signature Library (text-tells)

The shipped, project-agnostic catalog of AI-generated-text signatures. This is the
**seed source** for evaluator skills scaffolded by audit Step 4c-bis (the `text-eval`
scaffold) and the **comparison baseline** for the pattern-library gap check
([creative-integrity.md](../creative-integrity.md) § Pattern-Library Gap Check).

**Policy lives elsewhere — read it first, never restate it here.** Severity
architecture, the cluster-density rule, the voice-protection gate, and the scrub-loop
spec are canonical in [creative-integrity.md](../creative-integrity.md) (Nine Scrub
Principles 1, 5, 7; § Canonical Scrub-Loop Spec). This file carries detection content
only: pattern → tell → falsifiable test.

## How to apply this library

1. **Clustering, not signals** (principle 1). No pattern below blocks in isolation
   unless its row says so. Default escalation: 1 signal in a passage → CONSIDER;
   2 → SHOULD FIX; 3+ → MUST FIX. The exceptions are marked **[hard]** — mechanical
   defects and factual-integrity failures that are blocking at first occurrence.
2. **Dedupe by mechanism when counting clusters.** Two library rows describing one
   underlying mechanism count ONCE toward density. Never let catalog granularity
   lower the effective blocking threshold.
3. **Voice protection** (principle 5). Any flagged pattern matching a documented
   voice-profile characteristic demotes to CONSIDER. Absent a voice profile, every
   voice-dependent judgment in this library is advisory-only.
4. **Per-project hard directives override defaults.** A project may elevate any
   pattern to zero-tolerance MUST FIX by its own directive (common examples:
   em-dashes, rhetorical colons). Those elevations live in the project's skills,
   never in this shipped file.
5. **Tests are the contract** (principle 9). Apply the test column, not vibes. A
   pattern added locally without a falsifiable test is not done.

---

## Tier 1 — Surface tells (grep-able; advisory by default, route to hooks/linters)

### Character & punctuation

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Em-/en-dash density | Heavy `—`/`–` use where the genre or author norm is lighter | Count per 1,000 words against the author/genre baseline; pair with the semicolon/parenthesis-scarcity check below |
| Rhetorical colons | Setup-punchline: "The result: a seamless experience." / "Here's the truth: it doesn't work." | Restructure as a plain sentence; if nothing is lost, it was emphasis theater. Never flag list introductions, URLs, timestamps, dialogue attribution, or footnote syntax |
| Punctuation-regularity bundle | 100% Oxford commas, zero typos, no sentence-initial And/But, no fragments — combined with heavy dashes but near-zero semicolons and parentheses | Tally serial commas, semicolons, parentheses per 1,000 words vs. baseline; perfect uniformity plus the dash/semicolon skew flags it |
| Curly/straight quote seams | Mixed “curly” and "straight" quotes or apostrophes in adjacent paragraphs | Regex both forms; consistent use is human/tooling, mixed pairs mark a paste seam |
| Invisible Unicode **[hard]** | Zero-width characters (U+200B–U+200D, U+FEFF), narrow no-break space (U+202F), bidi controls (U+202A–E, U+2066–9), tag block (U+E0000–E007F), Private Use Area | Mechanical scan; report as clusters, not individual positions |

### Pipeline artifacts (near-conclusive; **[hard]** — mechanical defects, not style judgments)

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Citation-machinery residue | `:contentReference[oaicite:N]{index=N}`, `oai_citation`, `【85†L261-269】`, `[web:1]`, `[attached_file:1]`, `grok_render_citation_card_json`, `?utm_source=chatgpt.com` in URLs | Grep; any hit is effectively proof of an unedited paste |
| Unfilled placeholders | `[Your Name]`, `[Describe the specific section...]`, `2025-XX-XX`, `PASTE_URL_HERE`, `INSERT_SOURCE_URL_30` | Grep bracketed imperatives and XX-dates |
| Cross-markup leakage | Markdown in a non-Markdown venue (`## headings` in wikitext, `**bold**` in plain-text email), broken emphasis (`**this **` with stray space), mismatched fence/heading dialects | Does the markup dialect match the platform's native one? Two interleaved markup languages is pipeline residue |

### Vocabulary & phrasing

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| AI vocabulary | "delve," "tapestry," "pivotal," "showcase," "underscores," "noteworthy," "realm," "beacon," "multifaceted," "meticulous," "intricate," "commendable," "paramount," "vibrant," "boasts," "leverage," "robust," "seamless" | Would the author use this word in conversation? Single uses are legitimate; density is the signal |
| Filler phrases | "It's worth noting that," "It should be mentioned," "One might argue," "In today's digital age/world" | Delete the phrase; if the sentence still works, it was filler |
| Latinate bias | "utilize" for use, "commence" for start, "demonstrate" for show | Substitute the short Anglo-Saxon word; meaning unchanged → inflation |
| Copulative avoidance | "serves as," "stands as," "marks," "boasts," "features," "offers," "refers to" systematically replacing is/are/has | Substitute is/are/has back in; if meaning is unchanged in nearly every instance, the verbs were inflation |
| Superlative stacking | "genuinely remarkable," "truly transformative" | Strip the intensifiers; nothing is lost |
| "From X to Y" construction | "From content creation to data analysis" | More than once per piece flags it |
| Sentence-frame openers | Recurring frame families: "When it comes to…," "In the world of…" | Count instances per frame family across the document |
| Knowledge-cutoff & RAG disclaimers | "As of my last update…"; RAG variant: "not widely documented in available sources… likely…," "maintains a low profile" for missing personal details | Grep the disclaimer families; any hit in published prose is residue |
| Connector overuse | "Furthermore," "Moreover," "Additionally" chained across consecutive sentences or paragraphs | Two or more in sequence; humans vary or drop connectives |

### Chat-frame leakage

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Chat-wrapper leakage | "I hope this helps," "Certainly!," "Would you like me to…," "Here is a more detailed breakdown" in artifacts with no conversational addressee | Identify the "you" being addressed; if the genre has none, the sentence deletes cleanly with zero loss |
| Sycophantic openers | "Great question!," "You're absolutely right!" surviving a paste | Does the opener evaluate the interlocutor rather than the subject? Delete it; nothing factual is lost |
| Canned process assurances | "I ensured the content aligns with the platform's guidelines," "I am committed to…" | Does the text assert compliance instead of exhibiting it? Strike the assurance; the substance is untouched |
| Prompt echo | Opening restates the assignment: "This report will discuss the background information related to the topic of the report…" | Does the opening paraphrase the brief rather than advance it? Delete; nothing lost |
| Exhaustive change-summaries | Commit messages / edit summaries as formal first-person paragraphs itemizing what was "ensured" and "avoided" | Does the metadata prose exceed and over-justify the actual diff? |

---

## Tier 2 — Structural tells (whole-document agent pass, not regex)

### Sentence & paragraph mechanics

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Uniform sentence length | Every sentence 15–20 words; low burstiness is the strongest statistical AI signal | In any 5-sentence stretch, all sentences within 5 words of each other |
| Inflexible paragraphing | All paragraphs 3–5 lines regardless of subject; no single-sentence emphasis paragraphs | Measure paragraph-length variance |
| Formulaic paragraph structure | Topic sentence → supporting evidence → summary sentence, every paragraph | Map the skeleton of consecutive paragraphs |
| Four-part paragraph arc | Claim → expansion → contrast → resolution, repeatedly; a primary structural fingerprint across LLMs | Map arcs across the document; 3+ identical arcs flags |
| Present-participial overload | "-ing" phrase sentence openers at 2–5× human rate | Count participial openers per page |
| Superficial participial analysis | "…reflecting broader trends and contributing to the city's evolving identity" tacked onto facts | Delete the "-ing" tail; was any information lost? |
| Imbalanced contractions | All contractions or zero, applied uniformly | Humans mix; uniformity in either direction flags |
| Perfect grammar, zero personality | No fragments, no "And"/"But" openers, no intentional rule-breaking for rhythm | Census deliberate irregularities; zero across a full piece flags |
| Inflection regularity | No strategic dips in energy, no pauses, no dynamic shifts | Read aloud; flat energy across sections flags |

### Document shape

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Thesis-first structure | Insight announced before support; essays explain, narratives reveal | Does the first paragraph give away the conclusion the piece then re-derives? |
| Staccato opening | First paragraphs read like bullet points in prose form | Read the first three paragraphs aloud as a list; if nothing breaks, flag |
| List-ification | Prose that wants to be bullets; bullets erupting mid-essay in genres that forbid them | Does the format match the venue's genre norms? |
| Symmetrical lists | Every item the same length, structure, and detail level | Real lists are messy; measure item variance |
| Listicle-in-disguise | Uniform bold-header-colon rhythm masquerading as prose sections | Strip the bold headers; does a numbered listicle remain? |
| Structural narration | "In this article, we will explore…" — the text narrates its own structure | Delete the narration; the structure still exists |
| Bookend callbacks | Closing echoes the opening sentence or image — a template move dressed as craft | Diff opening and closing; near-verbatim echo flags |
| Treadmill effect | 500 words, 100 words of new information | Summarize each paragraph in one clause; count repeated clauses |
| Oversized recap conclusion | Disproportionately long conclusion opening "Overall,"/"In conclusion,"/"In summary," restating the document | Delete the conclusion; if zero claims disappear from the piece, it was a recap shell |
| "Challenges / Future Outlook" outline | Stock final sections ("Challenges," "Future Prospects") of modal speculation ("could enhance…") regardless of topic | Do the final headings match the stock pair, and does the section contain only could/may speculation? |
| "Despite challenges" formula | "Despite its [positive], [subject] faces challenges…" — bad news wrapped in cotton wool | Restate the negative plainly; if the sentence resists, it was cushioning |
| Rhetorical closure patterns | Every piece ends with the same closure type (question, call to action, reflection) | Corpus check across the author's recent pieces |
| Closing with a question | Faux-profound ending that avoids commitment | Does the question substitute for a position the piece never takes? |
| Significance-frame repetition | Content-free signposts ("Here's the thing," "the part I keep coming back to") repeated through one document | Count per frame family, whole document: 1–2 allowed; 3 → SHOULD FIX; 4+ → MUST FIX (lower thresholds for short-form) |

### Markdown & heading style

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Title Case headings | All main words capitalized where the venue norm is sentence case | 100% Title Case consistency in a sentence-case venue; humans are inconsistent, models aren't |
| Mechanical boldface | Key terms bolded "key takeaways"-style, often every instance of a chosen phrase | Strip all bold; if no contrastive stress is lost (bold tracks topic nouns, not emphasis), it was mechanical |
| Emoji decoration | Emoji prefixed to headings or bullets (🧠 …, 🚨 …) | Delete every emoji; if the document reads identically, they were scaffolding |
| Skipped heading levels | Sections start at H3 with no H2 above (chat apps reserve top levels) | Outline the heading tree; a level gap almost never occurs in hand-formatted documents |
| Thematic break before every heading | Horizontal rule ahead of each section, a Markdown-chat habit | Rules before most headings, rather than at one or two deliberate breaks |
| Unnecessary mini-tables | Small 2-column "Key Statistics" tables for facts that fit in a sentence | Convert the table to prose; if it collapses into one sentence with nothing lost, it was decoration |

### Rhetoric clustering

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Contrastive negation | "It's not X. It's Y." / "Not because X, but because Y." The single most common AI tell | One use per piece can be craft; 3+ is a dead giveaway (cluster rule applies at full strength) |
| Contrastive inversion | "Wages were going up, taxes were going up, and growth wasn't." | Distinct mechanism from contrastive negation; count separately but dedupe against it when both describe one passage |
| Negative parallelism | False-misconception framing ("Many people think X. The truth is Y."), including the additive "not only… but also" frame | Was the misconception ever actually held, or manufactured to be corrected? |
| Triple beat | Three examples, three adjectives, three clauses — the rhythmic default | Count triads; vary or cut when they cluster |
| Epiphany machine | Every paragraph ends with a revelatory flourish or antithetical reframe | 3+ consecutive paragraph-final epiphanies flags |
| Self-posed revelation | "The result? Devastating." "The worst part? Nobody saw it coming." | Was anyone asking? Rewrite declaratively; if nothing is lost, it was pose |
| Balanced hedging | "While X, it's also true that Y" — performed nuance | Does the piece ever commit? Genuine complexity picks a side somewhere |
| Passive deflection | "It could be argued that…" | Who argues it? Name them or commit |

---

## Tier 3 — Compositional tells (judgment class; budget most effort here)

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Detail latch | A concrete noun ("Tuesday," "three") threaded back 3–5× for fake cohesion; the literal token stays activated in attention | A human varies the reference; count verbatim token repeats |
| Manufactured temporal specificity | "last Tuesday," "just yesterday" — arbitrary anchors simulating lived experience | Delete the anchor; if the story still works, it was manufactured |
| Redundant reintroduction | Restating an established fact with emphasis words ("a single Tuesday") to disguise repetition as rhetorical weight | Has the reader already been told this? |
| Elegant variation | Synonym-cycling one referent ("Yankilevsky… the artist… the non-conformist…") — repetition-penalty behavior | Count distinct surface forms per repeated referent; humans happily reuse the same word |
| Premature resolution | Every tension or contradiction resolved by paragraph end; nothing lingers | Find one unresolved thread; absence flags |
| Subtext vacuum | No irony, doubt, or unspoken implication — what you read is all there is | Can any sentence be read two ways on purpose? |
| Absence of digression | Straight line from thesis to conclusion; no "by the way," no associative leaps | Census asides and tangents; zero flags |
| Metaphor lock-in | One metaphor carrying through every section | Count sections leaning on the same vehicle |
| Inert metaphor | Labels the concept instead of enacting it ("things fell apart," "on thin ice") — reader decodes, gains nothing sensory | Does the metaphor commit to a physical reality (verb, state, sensory detail)? Inert in a key position (opening/closing/pivot) → SHOULD FIX; in body → CONSIDER |
| Generic-name default | Illustrative people/places default to maximally common names (Emily, Sarah, Main Street, "a small town") | Census the proper nouns; all-generic specifics flag |
| Source-count inflation | "Industry reports," "experts argue," "several publications" attached to one or two citations | Count plural attribution claims against actually cited distinct sources |
| Ghost citations **[hard]** | "Studies show…," "Experts agree…" with no source named | Name the study or cut the claim |
| Fabricated experience **[hard]** | First-person claims about the author's actions, clients, or experiences not supplied by the author | Provenance check; never invent — ask. Factual-integrity class, blocking at first occurrence |
| False vulnerability | "I'll be the first to admit I don't have all the answers here" — pre-calculated, costs nothing | Does the admission carry real stakes or information? |
| Announced humor | "Here's the irony," "The funny thing is" — real wit is deadpan | Delete the announcement; the joke either lands or never existed |
| Patronizing analogy | "Think of it as…," "It's like…" assuming a novice reader | Would the intended reader understand without the analogy? |
| Hyperbolic scope | "companies everywhere," "the entire industry," "everyone knows" when evidence supports a subset | Could someone challenge the scope claim? If yes, shrink it |
| Abstracting humans | Organizations doing things instead of people | Rewrite one instance with a person as subject; if it sharpens, flag the rest |
| Personification of abstractions | "The data tells a story," "the market spoke," "AI chose to focus" | Replace with the human actor; meaning improves |
| Sensing without sensing | "The warm sun caressed the fields" — empty sensory language without raw specificity | A writer who was there names particulars ("burnt sugar and cardamom"); generic sensory adjectives flag |
| Flat emotional declarations | "I was deeply moved." Emotions named with adjectives, not shown through behavior | Replace the named emotion with observed behavior; if impossible, nothing was witnessed |
| Invented concept labels | "the supervision paradox," "the acceleration trap" — abstract noun appended without grounding | Is the label used by anyone else, or load-bearing beyond one paragraph? |
| Wit-shaped noise **[hard]** (single-line content) | Epigram/caption imitating a wit beat (clipped fragment, possessive twist, personification) with unresolvable referents | Point every noun/pronoun/possessive at exactly one thing in the scene or argument; in single-line content, ONE unresolved referent IS the flag (cluster exemption) |
| Over-explanation of basics | Defining "email" in an email-marketing piece | Does the intended audience already know this? |
| Explaining the point | Restating what was just shown | If shown, no explanation is needed; delete and re-read |
| Vague pronoun referents | "their efforts," "this" with no clear antecedent | Point each pronoun at its noun; failures flag |
| Nice-nice wrap | "Both have strong points." Refuses to pick sides | Does the piece ever say "this one wins"? |
| Motivational-poster tone | Relentless positivity; negatives always softened | Find one negative stated plainly; absence flags |
| Heady abstraction | Jargon without concrete grounding | Ground the abstraction in a lived example; if the text never does, flag |
| Meta-commentary on source form | "tucked into a parenthetical," "buried in a footnote" — describes how a source structured text, not what was said | Does the sentence describe human behavior or grammatical architecture? |
| Unnatural references | "in between," "the former/the latter," "as mentioned above," "aforementioned" — grammatically valid, linguistically dead | Would anyone say this aloud? |
| Theme over-explanation *(narrative)* | The story states its own theme instead of dramatizing it | Cut the thesis sentences; does the story still carry the theme? |
| Single-track tidy plotting *(narrative)* | One plot thread, no loose ends, every setup paid off mechanically | Census abandoned threads and accidents; zero flags |
| Moral-ambiguity flattening *(narrative)* | Every character clearly good or bad; conflicts resolve justly | Find one character the reader is unsure about |
| Legacy framing | "stands as a testament," unprompted "Legacy" sections, undue significance attached to ordinary subjects | Is the significance claim sourced or manufactured? |

---

## Corpus-level tells (sibling/author comparison; invisible to single-document passes)

| Pattern | Tell / example | Falsifiable test |
|---|---|---|
| Cross-document uniformity | Successive outputs converge to one structural shape | Sibling-comparison pass: map the skeletons of the author's recent pieces; identical shapes flag |
| Intra-author style shift | Abrupt jump to flawless formal prose amid an author's weaker writing; tone flips mid-document | Diff against the same author's informal writing (comments, messages); a discontinuity in error rate is the tell |
| Locale mismatch | American spelling/idiom in text whose author and topic are British/Indian/Australian English | Check -ize/-ise, -or/-our consistency against the author's other output and the topic's ties |
| Word whiskers | A distinctive phrase reused across sibling pieces ("room to think in" three pieces running) | Grep the phrase across the sibling set |
| Concept duplication | Two sibling pieces arguing the same central idea | Summarize each sibling's thesis in one line; collisions flag |
| Metaphor reuse | The same metaphor carrying weight in multiple sibling pieces | Census vehicles across siblings |
| Callback crutch | The same earlier piece referenced in 2+ subsequent pieces | Count references per target across siblings |
| Structural echo / neighborhood moves | Same opening or closing move as the last 2–3 sibling pieces (both open with a statistic; both close with a question) | Compare first/last moves across the neighborhood; duplicating 1 sibling → SHOULD FIX, 2+ → MUST FIX |

---

## Overbuilt-prose signals (cluster-scored; the read-aloud test governs)

**Test:** read the sentence aloud. If you would pause to restructure it mid-sentence,
it is a candidate signal. Signals cluster-score per the density rule (dedupe by
mechanism): nested conditionals ("if X, then Y, and if Y, then Z"); parallel
constructions for rhetorical effect; triple-or-more cascades ("Not X. Not Y. Not Z.");
3+ dependent clauses before the point lands; chiasmus / A-B-B-A mirroring; literary-
device density (more than 2 distinct devices in one paragraph); stacked appositive
chains; compound structures doing double duty; front-loaded information density;
stripped texture words (missing "other," "too," "also," "actually"); temporal
scaffolding (constructing before/after relationships the sequence already carries).

**Functional-rhetoric test (before flagging any device):** rewrite it as plain prose.
If meaning is lost — emotional resonance, reader trust, the idea's force — the device
is functional: reduce to CONSIDER. If meaning survives, the device is decorative:
keep the flag. Voice-protected devices still count toward cluster totals (protection
lowers individual severity, never the structural assessment).

## Flow & connectivity checks

| Pattern | Problem | Test |
|---|---|---|
| Orphaned statements | "Then I added X. Y has a texture." Reader must infer the relation | Make the connection explicit; if no connection exists, the sentences don't belong together |
| Compressed bullets as prose | Short declaratives missing "because," "which means," "so that" | Read as a list; if nothing breaks, it was a list |
| Ungrounded borrowed concepts | Quoted phrase introduced without how the author encountered it, then reused as if owned | Where did the author meet this idea? If the text never says, flag |
| Topic collisions | Sentence A introduces a concept; sentence B assumes understanding with no bridge | Insert the missing bridge clause; if it changes meaning, the gap was real |
| Dangling references | "I wrote about this recently" (no link); "This is where X comes in" (vague "this") | Resolve every reference to a target |
| Product/tool drops | Insight immediately followed by "I use Tool X for this" — promotional whiplash | Delete the drop; if the argument is untouched, it was an ad |
| Filler word echo | The same non-thematic word twice in one paragraph ("sitting with," "noted," "meanwhile") | Is the repeated word carrying the paragraph's central idea? Thematic repetition is craft; filler repetition is sloppiness |

## Human-presence markers (check FOR these before flagging anything)

A piece with 4+ strong markers plus a few rhetorical devices is human writing under
revision pressure, not AI writing — surface an over-correction warning before
requiring changes (principle 5; advisory-only absent a documented voice profile, and
evidence-not-proof in both directions on technical or non-English content).

| Marker | What to look for |
|---|---|
| First-person presence | "I" early and recurring naturally; the author is present, not observing from nowhere |
| Lived experience | Specific sensory details, concrete provenance, named places/people the author encountered |
| Genuine commitment | Clear positions; says "I don't know" rather than performing balance |
| Irregular rhythm | Sentence lengths vary wildly — very short against very long |
| Texture words | The conversational filler AI strips: "other," "too," "also," "actually," "just," "really" |
| Fragments & asides | Fragments for emphasis, parentheticals, mid-sentence pivots |
| Contractions | Natural "didn't," "wasn't," "I'd" against formal alternatives |
| Functional wit | Humor that advances the argument; deadpan, self-implicating — well-placed wit is a strong human tell |

**Never fake imperfections.** Fabricated rough edges are themselves a tell (false
vulnerability, above).

## Per-project adaptation

- **Hard directives:** projects elevate patterns (em-dashes, rhetorical colons, client
  language, pronoun rules) to zero-tolerance via their own directive blocks. The gap
  check never proposes demoting a project's elevation to match this file's defaults.
- **Voice profile:** every voice-dependent test here activates fully only against a
  documented voice profile; otherwise advisory-only.
- **Content-type calibration:** short-form content (posts, teasers, captions) takes
  single-signal severity and skips corpus checks; the wit-shaped-noise single-line
  exemption applies. Long-form takes the full library. The owning skill defines its
  calibration table.
- **Living library** (principle 9): projects add local patterns with example +
  falsifiable test via the Pattern-Intake Protocol in creative-integrity.md. Local
  additions are the project's own; the gap check only ever proposes additions FROM
  this file, never edits or removals of local rows.
<!-- /origin -->
