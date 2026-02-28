A five-mode I/O diagnostic command that forms a complete cycle: instrument → run → analyze → fix → revert → verify.

## Usage

```
/analyze-io-timing-log-and-fix                    # Default: same as --show
/analyze-io-timing-log-and-fix --log              # Ask toggle preference → explore project → output implementation prompt
/analyze-io-timing-log-and-fix --fix [log-path]   # Analyze log file → fix problems → record results
/analyze-io-timing-log-and-fix --show             # Extract current logging coverage and rationale from codebase
/analyze-io-timing-log-and-fix --revert [--all]    # Revert previously applied --fix changes using saved markers
/analyze-io-timing-log-and-fix --status           # Show history: when --log and --fix were run, what was found
```

**Default behavior (no parameter):** Run `--show` — extract current logging coverage and gap analysis from the live codebase.

All modes that modify the project (`--log`, `--fix`, `--revert`) append a record to `.io-diag/session-log.md` in the project root. `--status` reads this file.

---

# MODE: --log

Explore the current project, ask about the toggle mechanism, and produce a ready-to-paste Claude prompt that implements the proven I/O timing logger pattern in this project.

## Step 1: Ask About the Toggle Mechanism

Before exploring the project, ask the user:

> How should the I/O debug logger be enabled/disabled in this project?
>
> 1. **GUI settings toggle** — adds a switch in the app's existing settings/preferences screen (good for end-user control or sharing with teammates)
> 2. **Environment variable** — `IO_DEBUG=1` set in terminal or launch config (good for server apps, CI, headless tools)
> 3. **Both** — GUI toggle as the primary mechanism, env var as a fallback for CI/headless use
> 4. **Defaults write / UserDefaults** — macOS/iOS native: `defaults write <bundle-id> debugIO 1` (no UI required, persists across launches)

Wait for the user's answer before proceeding. If they're unsure, recommend the option that fits their platform:
- Native macOS/iOS app → option 4 (UserDefaults) or option 1 (GUI)
- Server/CLI/web → option 2 (env var)
- Shared team tool or app with Settings screen → option 1 or 3

## Step 2: Explore the Project

Read the project to understand:
- **Language and platform** (Swift/macOS, TypeScript/Node, Python, Go, etc.)
- **I/O operations**: file reads/writes, database queries, network calls, cache operations
- **FS monitoring**: directory watchers, file observers, polling loops, inotify/FSEvents/kqueue/chokidar
- **Threading model**: main thread + GCD, async/await, event loop, worker threads, coroutines
- **Callback/event patterns**: delegates, closures, observers, event emitters, pub/sub
- **Existing debug infrastructure**: any logging utilities, debug flags, settings screens/env vars
- **Existing settings mechanism** (if toggle = GUI): where the settings screen is, what pattern it uses

Focus on files with heavy or repeated I/O. Look for:
- Functions that load collections from disk or network
- Monitor/watcher callbacks that trigger cascading reads
- Save/write operations that might re-trigger their own monitor
- Any operation that runs on app startup or on every user keystroke

## Step 3: Identify Hotspots

For each I/O hotspot found, note:
- Function name and file:line
- What triggers it (user action, timer, file change, every keystroke, etc.)
- What it does (reads N items, writes to disk, queries DB)
- Whether it runs on the main thread / event loop
- Risk level: HIGH (blocks main thread or called every keystroke), MEDIUM (called frequently but not per-keystroke), LOW (one-time or rare)

## Step 4: Map the Logger Pattern to This Project

The proven pattern (developed on Note-n-Post / Swift + GCD) has these components. Map each to this project's language and conventions:

### Logger Utility
A singleton or module-level logger with:
- **Enable/disable toggle** — implement using the mechanism chosen in Step 1
- **`timed(label, block)`** — wraps any I/O block, logs label + wall-clock duration
- **`log(message)`** — freeform message with thread/context prefix
- **Thread/context annotation**:
  - Swift: `Thread.isMainThread ? "MAIN" : "bg"`
  - Node.js: `"event-loop"` always; note `"worker"` if using worker_threads
  - Python: `threading.current_thread().name`; async: `"async"` vs `"sync-call"`
  - Go: inject a label into context or use a goroutine-local tag
- **Duration thresholds**: ⚠️ > 50ms (slow), 🚨 > 200ms (visible stall / likely user-felt)
- **Log prefix format**: `[IO:<context>] <label>: <duration>ms [⚠️/🚨]`

### Settings Toggle Implementation (based on user choice in Step 1)

**GUI toggle**: Add a developer/debug section to the existing settings screen. A simple boolean toggle that sets the enable/disable flag. Label it clearly (e.g. "Log I/O timing"). Note: keep it in a "Developer" or "Advanced" section — not prominent in normal use.

**Environment variable**: Check `process.env.IO_DEBUG` / `os.environ.get("IO_DEBUG")` / `os.Getenv("IO_DEBUG")` on init. Any truthy value enables logging. Document in project README or .env.example.

**Both**: Check env var first (for CI/headless), fall back to GUI toggle setting.

**UserDefaults**: Read `UserDefaults.standard.bool(forKey: "debugIO")` on each call (so toggling takes effect immediately without restart). Enable from Terminal: `defaults write <bundle-id> debugIO 1`.

### FS Event Labeling (if project has file monitoring)
- Snapshot the watched directory (filename → mtime) when monitoring starts
- On each event, diff current snapshot against previous; log which files changed
- `FS event [<label>] — modified: <filename>`
- `FS event [<label>] — no file diff (metadata/hidden file change?)`

### Self-Write Guard (if project writes files it also watches)
- `pendingSelfWrites` counter (or equivalent)
- Increment before any own-initiated write; decrement after 150–300ms delay
- In monitor callback: return early if counter > 0, logging `suppressed (self-write)`
- Wrap all own-initiated writes in the guard

### Rate Warning (on hot-path callbacks)
- Rolling timestamp array, pruned to last 1 second on each call
- If count > threshold (3), log `⚠️ <fn>: N calls in 1s — possible feedback loop`

### Debounce for Expensive Callbacks
- If no debounce exists: replace immediate invocation with a cancel-and-reschedule timer (300–500ms)
- N rapid events → exactly 1 handler execution

## Step 5: Output the Implementation Prompt

### Output A — Standalone Implementation Prompt

Clearly delimited, self-contained, paste into any Claude Code session:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPLEMENTATION PROMPT — paste into Claude Code session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Implement I/O timing and diagnostic logging in this project.

Pattern reference: IODebugLogger from Note-n-Post (Swift/macOS) — proven to catch
feedback loops, main-thread blocks, and hot-path frequency issues.
Adapt to [detected language/framework].

Toggle mechanism: [chosen mechanism from Step 1, with exact implementation]

Files to create or modify:
[list each file, what to add/change, in implementation order]

Hotspots to instrument (HIGH priority first):
[each hotspot: file:function → what to wrap with timed() or log()]

FS event labeling: [yes/no + how to implement for this project]
Self-write guard: [yes/no + which writes to guard + guard implementation]
Rate warning: [which callbacks + threshold]
Debounce: [yes/no + where + interval]

Expected log output when working correctly:
[IO:bg]   loadItems: 12.3ms
[IO:MAIN] saveState: 8.1ms ⚠️ (should be on bg thread)
FS event [data] — modified: state.json
callback suppressed (self-write)
[IO:bg→main] reloadFromDisk: END — 34.2ms (+1 new, -0 removed)

How to enable: [exact steps based on chosen toggle mechanism]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Output B — /ddd-update Compatible Line

```
/ddd-update "Add I/O timing diagnostic logger: [concise description — logger utility, toggle mechanism, hotspots instrumented, self-write guard if applicable, rate warning]"
```

## Step 6: Write Session Record

Create `.io-diag/` directory if it doesn't exist. Append to `.io-diag/session-log.md`:

```markdown
## [YYYY-MM-DD] — --log
Language: [detected]
Toggle: [chosen mechanism]
Hotspots identified: N
  HIGH: [list]
  MEDIUM: [list]
FS labeling: yes/no
Self-write guard: yes/no
Implementation prompt: generated
/ddd-update line: included
```

---

# MODE: --fix

Analyze a log file produced by `--log` instrumentation and apply targeted code fixes.

If no path is given, ask the user to paste log content or provide a file path.

## Log Format Reference

```
[IO:MAIN]     <message>   — on main/event-loop thread (potential freeze/block)
[IO:bg]       <message>   — on background thread/worker (correct)
[IO:bg→main]  <message>   — bg I/O dispatched to main for state update (correct)
```

| Log Line | Meaning |
|----------|---------|
| `FS event [<label>] — modified: <file>` | Exact file that changed — the trigger |
| `FS event [<label>] — no file diff` | Monitor fired but no file diff found — metadata/hidden/temp |
| `callback fired` / `onExternalChange fired` | Monitor reached app logic — action will follow |
| `suppressed (self-write)` | Correctly blocked — expected after own writes |
| `⚠️ <fn>: N calls in 1s — possible feedback loop` | Rate warning |
| `<label>: START (bg thread)` | Correct — I/O on background thread |
| `<label>: START (on MAIN ⚠️ thread)` | Bug — blocking main thread |
| `<label>: END — Xms [⚠️/🚨]` | Duration. ⚠️ = >50ms, 🚨 = >200ms |

## Step 1: Parse and Build Timeline

Build a condensed chronological event chain. Group events into cause-and-effect sequences:
- `FS event` → `fired/suppressed` → `load/reload` is one chain
- Label each outcome: **SUPPRESSED** | **EXECUTED** | **DEBOUNCED** | **BLOCKED**
- Flag any file that appears in multiple consecutive FS events (unguarded write)

## Step 2: Detect Patterns

### A. Feedback Loop
`FS event` for an own-written file (state, cache, config) followed by an unsuppressed `fired`. The self-write guard either doesn't exist or doesn't cover this write path.

### B. Main Thread / Event Loop Blocking
Any `[IO:MAIN]` with timing, or `START (on MAIN ⚠️ thread)`. Direct cause of UI freeze, request timeout, or event loop stall.

### C. Rate Violation
More than 3 `fired` events in any 1-second window, or explicit rate warning lines. Indicates debounce missing or upstream write rate too high.

### D. Slow Individual Operations
Any ⚠️ (>50ms) or 🚨 (>200ms). Note operation, duration, thread.

### E. Excessive Monitor Chatter
High `FS event` count relative to user actions. Debounce may be working (collapsing executions) but the trigger rate itself wastes resources.

### F. Missing File Attribution
`no file diff` on >20% of FS events. Snapshot diff may be missing hidden files, or iCloud metadata is triggering events. Flag for investigation.

### G. Unguarded Writes
Own-written files appearing in FS events with unsuppressed callbacks. Find the write call and add the self-write guard.

## Step 3: Root Cause Analysis

For each pattern, read the source files and confirm before fixing:

| Pattern | Where to look | What to verify |
|---------|--------------|----------------|
| Feedback loop | State/cache write sites | Every own-initiated write inside the guard? |
| Main thread I/O | Load/reload functions | Disk reads dispatched to background queue? |
| High call frequency | Monitor callback | Debounce timer present and cancel-rescheduling? |
| Guard not suppressing | Self-write guard impl | Delay long enough (>150ms)? Counter scoped correctly? |
| Slow despite bg thread | The I/O operation itself | N×M loop? Loading too much? Blocking call inside async? |
| No file diff | FS snapshot logic | `lastSnapshot` initialized before monitoring starts? |

## Step 4: Fix

For each confirmed root cause:
1. Read the affected file
2. Apply the minimal targeted fix
3. Wrap the fix with marker comments (see below)
4. Explain what changed and why

### Marker Comments

Wrap every fix between `IO-FIX-START` / `IO-FIX-END` tags with a unique fix ID so `--revert` can find and undo them.

**Fix ID format:** `io-fix-YYYY-MM-DD-NNN` (NNN is sequential within the session, starting at 001)

**Comment syntax adapts to language:**
| Languages | Syntax |
|-----------|--------|
| Swift, JS, TS, Go, Rust, Java, C, C++ | `// IO-FIX-START [id]` … `// IO-FIX-END [id]` |
| Python, Ruby, Shell | `# IO-FIX-START [id]` … `# IO-FIX-END [id]` |
| SQL, Lua | `-- IO-FIX-START [id]` … `-- IO-FIX-END [id]` |
| CSS | `/* IO-FIX-START [id] */` … `/* IO-FIX-END [id] */` |

**Marker placement:**
- If a fix **replaces** existing code: markers wrap the new replacement code
- If a fix **adds** new code (e.g., adding a debounce timer): markers wrap the addition

**Example (Swift):**
```swift
// IO-FIX-START [io-fix-2026-02-28-001]
DispatchQueue.global(qos: .userInitiated).async {
    self.loadItems()
}
// IO-FIX-END [io-fix-2026-02-28-001]
```

### Fix Manifest

Save all fix metadata to `.io-diag/fix-manifest.json` so `--revert` can restore originals.

**Format:**
```json
{
  "io-fix-2026-02-28-001": {
    "file": "Sources/DataManager.swift",
    "description": "Move loadItems() to background thread",
    "pattern": "main-thread-io",
    "original": "self.loadItems()",
    "applied": "2026-02-28"
  },
  "io-fix-2026-02-28-002": {
    "file": "Sources/Monitor.swift",
    "description": "Add debounce timer to FS callback",
    "pattern": "rate-violation",
    "original": null,
    "applied": "2026-02-28"
  }
}
```

- **file**: relative path to the modified file
- **description**: what the fix does
- **pattern**: which issue pattern from Step 2 (e.g., `feedback-loop`, `main-thread-io`, `rate-violation`, `slow-operation`, `unguarded-write`)
- **original**: the exact code that was replaced, or `null` if the fix is a pure addition
- **applied**: date the fix was applied

If `.io-diag/fix-manifest.json` already exists (from a previous `--fix` session), append new entries to the existing object. Never overwrite previous entries.

Run the build/test step after all fixes.

## Step 5: Output Report

```
## I/O Log Analysis Report

### Health Score: [🟢 Good | 🟡 Degraded | 🔴 Critical]

### Event Summary
- Total FS events: N
- Callbacks fired: N  |  suppressed: N  (X% suppression rate)
- Handler calls: N   |  actually executed: N  (debounce efficiency)
- Main thread I/O incidents: N
- Slow (>50ms): N    |  Critical (>200ms): N

### Event Chain Sample
[3–5 representative chains with outcome labels]

### Issues Found
| # | Pattern | Severity | Location | Description |
|---|---------|----------|----------|-------------|

### Fixes Applied
[Each fix: description + before/after snippet]

### Remaining Risks
[Confirmed issues that need runtime data or broader refactor]

### What to Log Next Time
[Missing instrumentation points that would speed up the next diagnosis]
```

## Step 6: Append Session Record

Append to `.io-diag/session-log.md`:

```markdown
## [YYYY-MM-DD] — --fix
Log file: [path or "pasted"]
Health before: 🔴/🟡/🟢
Issues found: N
  [list each: pattern — location]
Fixes applied: N
  [list each: what changed — file:line]
Manifest: .io-diag/fix-manifest.json (N entries added)
Health after: 🔴/🟡/🟢 (estimated — re-run --fix after next log collection to confirm)
Remaining risks: [list or "none"]
```

---

# MODE: --revert

Undo previously applied `--fix` changes by restoring original code using the marker comments and fix manifest.

## Step 1: Read Manifest

Load `.io-diag/fix-manifest.json`.
- If the file does not exist: report "No fixes to revert. No fix manifest found at `.io-diag/fix-manifest.json`." and stop.
- If the file is empty (no entries): report "No fixes to revert. Manifest is empty." and stop.

## Step 2: List Applied Fixes

Display all entries from the manifest:

```
Applied fixes:
  [io-fix-2026-02-28-001]  Sources/DataManager.swift  —  Move loadItems() to background thread  (applied 2026-02-28)
  [io-fix-2026-02-28-002]  Sources/Monitor.swift      —  Add debounce timer to FS callback       (applied 2026-02-28)
```

## Step 3: Ask What to Revert

If `--all` flag is passed: skip this step and revert all fixes.

Otherwise, ask the user:

> Which fixes should be reverted?
> 1. **All** — revert every fix listed above
> 2. **Select by ID** — enter one or more fix IDs (comma-separated)

Wait for the user's answer. If they select by ID, validate that each ID exists in the manifest.

## Step 4: Revert Each Selected Fix

For each fix to revert:

1. Read the file specified in the manifest entry
2. Search for the `IO-FIX-START [id]` and `IO-FIX-END [id]` markers
3. If markers are **found**:
   - If `original` is not `null`: replace the entire block (start marker + content + end marker) with the original code
   - If `original` is `null` (pure addition): delete the entire block including both markers and all content between them
4. If markers are **not found**: warn "Fix `[id]` markers not found in `[file]` — may have been manually edited. Skipping." and continue with remaining fixes

## Step 5: Update Manifest

Remove all successfully reverted entries from `.io-diag/fix-manifest.json`.
- If the manifest is now empty: delete the file entirely
- If entries remain (partial revert or skipped fixes): write the updated manifest

## Step 6: Build and Test

Run the project's build/test step to verify the revert didn't break anything. Report results.

## Step 7: Append Session Record

Append to `.io-diag/session-log.md`:

```markdown
## [YYYY-MM-DD] — --revert
Fixes reverted: N
  [list each: id — file — description]
Fixes skipped: N (markers not found)
  [list each if any: id — file — reason]
Manifest: .io-diag/fix-manifest.json (N entries remaining, or "deleted — no entries remaining")
Build/test: passed/failed
```

---

# MODE: --show

Extract and display the current I/O logging implementation from the codebase — coverage, rationale, gaps. Works whether or not `--log` was previously run. Does not modify any files.

## Step 1: Find the Logger Utility

Search the codebase for the logger implementation:
- Look for `IODebugLogger`, `IOLogger`, `ioLogger`, `debugIO`, `IO_DEBUG`, or equivalent
- If not found, report that logging has not been implemented yet and suggest running `--log`
- If found: note the file location, the enable/disable mechanism, and the methods it exposes

## Step 2: Map Instrumentation Coverage

Search for all call sites:
- `timed(` / `.timed(` calls — wrapping I/O operations
- `log(` / `.log(` calls from the logger (exclude unrelated log calls)
- Self-write guard usages (`pendingSelfWrites`, `withSelfWriteGuard`, or equivalent)
- Rate warning counters
- FS event snapshot logic in monitor callbacks

For each instrumented site, record: file, function, what it's measuring, why it matters.

## Step 3: Gap Analysis

Cross-reference instrumented sites against the hotspots identified at `--log` time (from `.io-diag/session-log.md` if it exists) or by re-scanning the codebase for I/O operations.

Flag any hotspot that is NOT instrumented — especially:
- Functions that do disk reads/writes but have no `timed()` wrapper
- Monitor callbacks without FS event labeling
- Write sites not wrapped in the self-write guard
- Hot-path callbacks without rate warning

## Step 4: Check Enable/Disable

Verify the toggle mechanism works as documented:
- Find where the flag is read
- Note how to enable it (exact command, setting, or env var)
- Note whether it takes effect immediately or requires restart

## Step 5: Output Coverage Report

```
## I/O Logging Coverage Report

### Logger: [file location]
Enable: [exact command/step to turn on]

### Instrumented Sites
| File | Function | What's measured | Guard/Rate |
|------|----------|-----------------|------------|
| ...  | ...      | ...             | ...        |

### Coverage by Risk Level
HIGH risk hotspots:   N instrumented / N total  [🟢/🟡/🔴]
MEDIUM risk hotspots: N instrumented / N total
LOW risk hotspots:    N instrumented / N total

### Gaps (Not Instrumented)
| File | Function | Risk | Why it matters |
|------|----------|------|----------------|

### Self-Write Guard
Writes guarded: N / N total own-initiated writes
[List any unguarded writes]

### Rate Warning
Callbacks with rate tracking: N / N hot-path callbacks

### What This Logging Can Detect
[List the patterns --fix will be able to identify given current instrumentation]

### What This Logging Cannot Detect (gaps)
[List patterns that are invisible due to missing instrumentation]
```

---

# MODE: --status

Show the diagnostic history for this project and current code state. Reads `.io-diag/session-log.md` if present and performs a quick live codebase scan.

## Step 1: Read Session Log

Check if `.io-diag/session-log.md` exists:
- If not: report "No diagnostic history found. Run `--log` to start."
- If found: parse all recorded sessions and display them chronologically

## Step 2: Quick Live Code Scan

Regardless of session log, do a fast scan of the codebase for key pattern presence:

| Pattern | Check |
|---------|-------|
| Logger utility | File exists with `timed()` and `log()` methods? |
| Self-write guard | Counter + guard wrapper present? |
| Debounce timer | Cancel-and-reschedule pattern in monitor callback? |
| Background I/O | Disk reads inside background queue dispatch? |
| Rate warning | Rolling timestamp array on hot-path callback? |
| FS snapshot diff | `lastSnapshot` or equivalent in monitor? |

Mark each: ✅ present / ⚠️ partial / ❌ missing

## Step 2b: Check Fix Manifest

Check if `.io-diag/fix-manifest.json` exists:
- If found: count entries and list them (ID, file, description, date applied)
- Note: these are `--fix` changes currently applied to the codebase that can be reverted with `--revert`

## Step 3: Output Status Summary

```
## I/O Diagnostic Status — [Project Name]

### Current Code State
Logger utility:      ✅/⚠️/❌
Self-write guard:    ✅/⚠️/❌
Debounce timer:      ✅/⚠️/❌
Background I/O:      ✅/⚠️/❌
Rate warning:        ✅/⚠️/❌
FS snapshot diff:    ✅/⚠️/❌

Overall: [🟢 Fully instrumented | 🟡 Partially instrumented | 🔴 Not instrumented]

### Applied Fixes (revertible)
[If .io-diag/fix-manifest.json exists:]
N fixes currently applied:
  [io-fix-YYYY-MM-DD-NNN]  file  —  description  (applied YYYY-MM-DD)
  ...
Run `--revert` to undo these changes.

[If no manifest: "No applied fixes."]

### Session History

#### [date] — --log
Toggle: [mechanism]
Hotspots targeted: N ([list])
Implementation prompt: generated

#### [date] — --fix  (log: [source])
Health before: 🔴/🟡/🟢  →  after: 🔴/🟡/🟢
Issues found: N | Fixed: N | Remaining: N
[brief list of what was fixed]

[...additional sessions in chronological order...]

### Trend
[If multiple --fix sessions exist: is health improving, stable, or regressing?]
[If only --log: "Logging implemented, no --fix runs yet — collect a log and run --fix"]
[If nothing: "No history — run --log to start"]

### Recommended Next Step
[Based on current state: run --log / collect log and run --fix / run --show to check coverage / system looks healthy]
```
