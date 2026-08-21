# GIT WORKFLOW

This document contains information on how to use `git` to use `c-unit-test-template` to develop a library and share the developed library with the consumer application.

# Cloning the repository

Clone the github repository using c-unit-test-template as template: from the c-unit-test-template repository home page on github select "Use this template -> Create new repository". Pay attention to select "use all branches".

 This is a preferred way rather than using `git clone <repo_url>` because using the template function on `github` does not copy the repository history.

Move to your new repository, compile the project, rename the library as needed, and check if the newly created repository contains the branch `lib-export`

```bash
PS C:\wag\ag-libraries\ag-console> git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/lib-export
  remotes/origin/main
```

**[If the branch exists]**

If you have cloned the repository in this way, you should see the branch lib-export.

Connect remote branch with local: this means tracking

```
git switch --track origin/lib-export
```

**[If the branch doesn't exist]**

If you forgot to select "use all branches" when cloning the repository through the `github` interface, the branch `lib-export` won't exist.

Create a branch that point to the folder of the library. Use the following command.

```
git subtree split --prefix=mylib -b lib-export	# create a LOCAL branch named lib-export that point to mylib
git push origin lib-export						# to push the new branch to the remote repository origin

NOTE: IF YOU WANT TRACKING, YOU MUST DO:

git push -u origin lib-export
where -u sets the upstream
```

NOTE: to delete a local branch you can use `git branch -D lib-export`

# Connecting the remote library (git subtree)

Guide to the commands for connecting the remote library (branch `lib-export`) into the `src/ag-hsm` folder of the consumer application project, using `git subtree`.

As an example, we use the library name [ag-hsm](https://github.com/AlexGiov/ag-hsm.git).

With `git subtree` the library code is copied ("vendored") into this repository: there is no nested `.git`, so whoever clones the project doesn't need any extra step (unlike submodules). In exchange, synchronizing updates and contributions requires the specific `git subtree` commands.

Run the commands from the project root (`c:\wag\ag-libraries\ag-hsm-example-apps`).

## 0. Preliminary check (optional but recommended)

Check that the repository and branch are reachable with your credentials, without changing anything locally:

```sh
git ls-remote https://github.com/AlexGiov/ag-hsm.git lib-export
```

If the command returns a commit hash, access works. If it asks for authentication or fails, this needs to be resolved before proceeding (e.g. credentials/SSH key for that repo).

## 1. Connect the remote repo

```sh
git remote add ag-hsm https://github.com/AlexGiov/ag-hsm.git
```

Adds a second "remote" to the local repo (in addition to `origin`, which points to `ag-hsm-example-apps`). This command alone **doesn't download anything**: it just creates an alias (`ag-hsm`) for the URL, used by the following commands.

To verify it was added:

```sh
git remote -v
```

## 2. Connect the folder to the remote branch (one-time)

```sh
git subtree add --prefix=src/ag-hsm ag-hsm lib-export --squash
```

This command:

- downloads the `lib-export` branch from the `ag-hsm` remote;
- creates the `src/ag-hsm` folder containing all the files from the branch;
- creates a local commit that imports these files into the main repo.

`--squash` compresses the entire history of the `lib-export` branch into a single merge commit, so this project's history doesn't get weighed down with all the library's commits. If the full library history needs to be preserved in the future, the operation can be repeated without `--squash` (but this is discouraged unless necessary).

This command must be run **only once**: if `src/ag-hsm` already exists, `git subtree add` will fail with an error (use `pull` instead, see below).

## 3. Download updates from the remote library

Whenever the `lib-export` branch receives new commits and you want to align with it:

```sh
git fetch ag-hsm lib-export
git subtree pull --prefix=src/ag-hsm ag-hsm lib-export --squash
```

`fetch` only downloads the references/commits into the local repo (without touching the files); `subtree pull` merges those changes into `src/ag-hsm`, keeping the history squashed. If there are conflicts between local changes and remote updates, resolve them like a normal Git merge (edit the conflicting files, then `git add` + `git commit`).

## 4. Push local changes to the library's remote branch

If you modify files inside `src/ag-hsm` and want to push the changes back to the `ag-hsm` repo (branch `lib-export`):

```sh
git subtree push --prefix=src/ag-hsm ag-hsm lib-export
```

This command reconstructs, from local history, only the commits related to `src/ag-hsm` and sends them to the `lib-export` branch of the `ag-hsm` remote.

**Note**: `subtree push` can be slow on repos with a lot of history, because it recomputes the sub-folder split on every run. A faster, more controllable alternative:

```sh
git subtree split --prefix=src/ag-hsm -b tmp-ag-hsm-push
git push ag-hsm tmp-ag-hsm-push:lib-export
git branch -D tmp-ag-hsm-push
```

`split` creates a temporary local branch (`tmp-ag-hsm-push`) containing only the history of `src/ag-hsm`; it is then pushed to the `lib-export` remote branch and deleted locally.

**Important**: always do a pull (point 3) before a push, to avoid your push diverging from remote updates and generating conflicts.

## Command summary

| Operation                      | Command                                                       |
| ------------------------------- | -------------------------------------------------------------- |
| Verify remote access            | `git ls-remote https://github.com/AlexGiov/ag-hsm.git lib-export` |
| Connect the remote               | `git remote add ag-hsm https://github.com/AlexGiov/ag-hsm.git` |
| Connect the folder (one-time)   | `git subtree add --prefix=src/ag-hsm ag-hsm lib-export --squash` |
| Download updates                 | `git fetch ag-hsm lib-export` + `git subtree pull --prefix=src/ag-hsm ag-hsm lib-export --squash` |
| Push local changes                | `git subtree push --prefix=src/ag-hsm ag-hsm lib-export`     |

# Working on the library: Syncing `main` and `lib-export` (bidirectional)

The following chapter covers library synchronization between the `main` branch and the `lib-export` branch. The `main` branch typically contains a tested new version of the library, while the `lib-export` branch typically contains changes from the consumer application.

The following chapters represent a learning path for the following scenario: **hotfixes committed directly to `origin/lib-export`**, which then need to flow back into `main`, while `main`'s own changes to `mylib/` still need to flow out to `lib-export` — without ever rewriting `lib-export`'s published history (consumers rely on `git subtree add/pull` against it, so rewriting it would break their clones).

If you only ever change `mylib/` from `main` and never touch `lib-export` directly, you don't need this: the simple `git subtree split` + push from the
main README is enough.

## 1. What these git subtree commands actually do

- **`git subtree split --prefix=mylib -b lib-export`** walks `main`'s history and synthesizes a *new, separate history* containing only the commits that touched `mylib/` — as if `mylib/` had always been its own repository. The result is written to the `lib-export` branch.
- **`git subtree merge --prefix=mylib <ref>`** does the opposite: it takes an external ref's tree (e.g. `origin/lib-export`) and merges it *into* the
  `mylib/` subdirectory of the current branch, via a normal, additive merge commit. Nothing is rewritten — it's just a merge like any other.
- **`--rejoin`** (used with `split`) adds an extra, harmless merge commit back onto the branch you split *from* (`main`). That commit records "this is the
  point where `main`'s `mylib/` and `lib-export` last agreed." Without it, git has no memory of previous splits, and every future split looks like a
  brand-new, unrelated history — which is exactly what forces a rewrite (and a force-push) of `lib-export`. `--rejoin` is what keeps future syncs
  fast-forwardable.

Note: unlike the consumer-side `git subtree add`/`pull` shown earlier in this document
(which use `--squash` to keep the consumer's history light), the `merge` in step A below
intentionally omits `--squash` — full-fidelity history is needed here so that future
`git subtree split --rejoin` runs can recognize prior sync points and stay
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
