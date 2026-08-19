# Syncing `main` and `lib-export` (bidirectional)

This document is a learning path for a scenario the basic [git subtree export](README.md#-exporting-mylib-with-git-subtree) workflow doesn't cover: **hotfixes committed directly to `origin/lib-export`**, which then need to flow back into `main`, while `main`'s own changes to `mylib/` still need to flow out to `lib-export` — without ever rewriting
`lib-export`'s published history (consumers rely on `git subtree add/pull`against it, so rewriting it would break their clones).

If you only ever change `mylib/` from `main` and never touch `lib-export`directly, you don't need this: the simple `git subtree split` + push from the
main README is enough.

## 1. What these git subtree commands actually do

- **`git subtree split --prefix=mylib -b lib-export`** walks `main`'s history and synthesizes a *new, separate history* containing only the commits that touched `mylib/` — as if `mylib/` had always been its own repository. The result is written to the `lib-export` branch.
- **`git subtree merge --prefix=mylib <ref>`** does the opposite: it takes an external ref's tree (e.g. `origin/lib-export`) and merges it *into* the
  `mylib/` subdirectory of the current branch, via a normal, additive merge commit. Nothing is rewritten — it's just a merge like any other.
- **`--rejoin`** (used with `split`) adds an extra, harmless merge commit back onto the branch you split *from* (`main`). That commit records "this is the
  point where `main`'s `mylib/` and `lib-export` last agreed." Without it, git has no memory of previous splits, and every future split looks like a
  brand-new, unrelated history — which is exactly what forces a rewrite (and a force-push) of `lib-export`. `--rejoin` is what keeps future syncs
  fast-forwardable.

## 2. Why order matters

You always want to **pull `lib-export`'s hotfixes into `main` first**, then **push `main`'s state back out to `lib-export`**. If you split first without merging in `lib-export`'s exclusive commits, the new split has no idea those commits exist, and the resulting `lib-export` branch diverges from `origin/lib-export` — the only way to publish it then would be a force-push, which we want to avoid.

Merging first means the split (step B below) walks a `main` history that *already contains* `lib-export`'s tip. So the freshly generated `lib-export` commit builds directly on top of `origin/lib-export`'s current tip: a plain fast-forward, no rewrite needed.

## 3. Step-by-step workflow

Make sure your working tree is clean (`git status`) before starting.

### Step 0 — Fetch both branches

```bash
git fetch origin main lib-export
```

### Step A — Pull `lib-export` hotfixes into `main`

```bash
git checkout main
git pull
git subtree merge --prefix=mylib origin/lib-export -m "Merge lib-export hotfixes into mylib/"
```

If this reports "Already up to date", `lib-export` had nothing new — skip to Step B. Otherwise, a merge commit is created on `main`.

**If there's a conflict**, git stops mid-merge and `git status` shows unmerged paths under `mylib/`. Resolve them like any normal merge conflict:

```bash
# edit the conflicted files under mylib/ to resolve the markers
git add mylib/<resolved-file>
git commit
```

Once the merge commit exists (clean or conflict-resolved), continue to Step B.

### Step B — Push `main`'s `mylib/` state back out to `lib-export`

```bash
git subtree split --prefix=mylib --rejoin --branch lib-export
```

This updates the local `lib-export` branch pointer and adds the `--rejoin`
marker commit to `main`.

### Step C — Verify before pushing anything

```bash
# Must succeed: confirms lib-export can fast-forward, no rewrite needed
git merge-base --is-ancestor origin/lib-export lib-export

# Must print nothing: confirms main:mylib and lib-export now hold the same tree
git diff main:mylib lib-export
```

If the first command fails, **stop** — see [Troubleshooting](#4-troubleshooting) below. Do not force-push to work around it.

### Step D — Push both branches

```bash
git push origin main
git push origin lib-export
```

Both are plain, fast-forward pushes — never add `--force`.

## 4. Troubleshooting

- **`merge-base --is-ancestor` fails (Step C)**: git can't find a common
  history point between the local `lib-export` and `origin/lib-export`. This
  usually means the `--rejoin` trail is missing — e.g. this is the very first
  time this workflow runs on this clone, or someone previously split/pushed
  `lib-export` without `--rejoin`. Don't force-push as a default fix; inspect
  `git log main -- mylib` and `git log lib-export` to understand where the
  histories actually differ, and reconcile manually (a one-time bootstrap
  exception may be unavoidable the very first time this workflow is adopted).
- **Step A conflicts every time**: usually means the same lines under
  `mylib/` are being edited both on `main` and directly on `lib-export`.
  Consider routing more changes through `main` only, and reserving direct
  `lib-export` commits for true emergency hotfixes.
- **Nothing to sync**: if both Step A and Step B report no changes, the
  branches are already aligned — just confirm with `git diff main:mylib lib-export`.

## 5. Quick reference (once you know the workflow)

```bash
git fetch origin main lib-export
git checkout main && git pull
git subtree merge --prefix=mylib origin/lib-export -m "Merge lib-export hotfixes into mylib/"
git subtree split --prefix=mylib --rejoin --branch lib-export
git merge-base --is-ancestor origin/lib-export lib-export && git diff main:mylib lib-export
git push origin main
git push origin lib-export
```
