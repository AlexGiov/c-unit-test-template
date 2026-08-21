# GIT WORKFLOW

This document contains information on how to use `git` to use `c-unit-test-template` to develop a library and share the developed library with the consumer application.

# Cloning the repository

Clone the github repository using c-unit-test-templete as template: from the c-unit-test-template repository home page on github select "using this tempalete -> Create new repository". Pay attention to select "use all branches".

 This is a preferred way rather than using `git clone <repo_url>`because using the template function on `github` do not copy the repository story.

Move to your new repository, compile the project, rename the library as needed, and check i the new created repository contains the branch `lib-export`

```bash
PS C:\wag\ag-libraries\ag-console> git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/lib-export
  remotes/origin/main
```

**[If the branch exist]**

If you have cloned in the manner way the reposistory you should see the branch lib-export.

Connect remote branch with local: this means tracking

```
git switch --track origin/lib-export
```

**[if the branch do not exist]**

If you forgotten to select " use all branches" cloning the repository through the `github` interface the branch `lib-export` won' t exists.

Create a branch that point to the folder of the library. Use the following command.

```
git subtree split --prefix=mylib -b lib-export	# create a LOCAL branch named lib-export that point to mylib
git push origin lib-export						# to push the new branch to the remote repository orgin

ATTENZIONE SE VUOI IL TRACKING DEVI FARE:

git push -u origin lib-export
dove -u è per settare l'upstream
```

NOTE: to delete a local branch you can use `git branch -D lib-export`

# Collegare la libreria remota (git subtree)

Guida ai comandi per collegare la libreria remota  (branch `lib-export`) nella cartella `src/ag-hsm` nel progetto della consumer application usando `git subtree`.

A titolo di esempio usiamo il nome per la libreria pari a  [ag-hsm](https://github.com/AlexGiov/ag-hsm.git)

Con `git subtree` il codice della libreria viene copiato ("vendorizzato") dentro questo repository: non c'e' nessun `.git` annidato, chi clona il progetto non deve fare nessun passo aggiuntivo (a differenza dei submodule). In cambio, sincronizzare aggiornamenti e contributi richiede gli specifici comandi `git subtree`.

Esegui i comandi dalla root del progetto (`c:\wag\ag-libraries\ag-hsm-example-apps`).

## 0. Verifica preliminare (opzionale ma consigliata)

Controlla che repository e branch siano raggiungibili con le tue credenziali, senza modificare nulla in locale:

```sh
git ls-remote https://github.com/AlexGiov/ag-hsm.git lib-export
```

Se il comando restituisce un hash di commit, l'accesso funziona. Se chiede autenticazione o fallisce, va risolto prima di proseguire (es. credenziali/SSH key per quel repo).

## 1. Collegare il repo remoto

```sh
git remote add ag-hsm https://github.com/AlexGiov/ag-hsm.git
```

Aggiunge un secondo "remote" al repo locale (oltre a `origin`, che punta a `ag-hsm-example-apps`). Questo comando da solo **non scarica nulla**: crea solo un alias (`ag-hsm`) verso l'URL, usato dai comandi successivi.

Per verificare che sia stato aggiunto:

```sh
git remote -v
```

## 2. Collegare la cartella al branch remoto (una tantum)

```sh
git subtree add --prefix=src/ag-hsm ag-hsm lib-export --squash
```

Questo comando:

- scarica il branch `lib-export` dal remote `ag-hsm`;
- crea la cartella `src/ag-hsm` con dentro tutti i file del branch;
- crea un commit locale che importa questi file nel repo principale.

`--squash` comprime tutta la storia del branch `lib-export` in un solo commit di merge, cosi' la storia di questo progetto non si appesantisce con tutti i commit della libreria. Se in futuro serve conservare la storia completa della lib, si puo' ripetere l'operazione senza `--squash` (ma e' sconsigliato se non necessario).

Questo comando va eseguito **una sola volta**: se `src/ag-hsm` esiste gia', `git subtree add` fallira' con un errore (usa invece `pull`, vedi sotto).

## 3. Scaricare aggiornamenti dalla libreria remota

Ogni volta che il branch `lib-export` riceve nuovi commit e vuoi allinearti:

```sh
git fetch ag-hsm lib-export
git subtree pull --prefix=src/ag-hsm ag-hsm lib-export --squash
```

Il `fetch` scarica solo i riferimenti/commit nel repo locale (senza toccare i file); il `subtree pull` fa il merge di quei cambiamenti dentro `src/ag-hsm`, mantenendo la storia squashata. Se ci sono conflitti tra modifiche locali e aggiornamenti remoti, vanno risolti come un normale merge Git (modifica i file in conflitto, poi `git add` + `git commit`).

## 4. Pushare cambiamenti locali al branch remoto della libreria

Se modifichi file dentro `src/ag-hsm` e vuoi riportare le modifiche sul repo `ag-hsm` (branch `lib-export`):

```sh
git subtree push --prefix=src/ag-hsm ag-hsm lib-export
```

Questo comando ricostruisce dalla cronologia locale i soli commit relativi a `src/ag-hsm` e li invia al branch `lib-export` del remote `ag-hsm`.

**Nota**: `subtree push` puo' essere lento su repo con molta storia, perche' ricalcola lo split della sotto-cartella ad ogni esecuzione. Un'alternativa piu' rapida e controllabile:

```sh
git subtree split --prefix=src/ag-hsm -b tmp-ag-hsm-push
git push ag-hsm tmp-ag-hsm-push:lib-export
git branch -D tmp-ag-hsm-push
```

`split` crea un branch temporaneo locale (`tmp-ag-hsm-push`) contenente solo la storia di `src/ag-hsm`; lo si pusha sul branch remoto `lib-export` e poi lo si elimina in locale.

**Importante**: fai sempre un pull (punto 3) prima di un push, per evitare che il tuo push diverga dagli aggiornamenti remoti e generi conflitti.

## Riepilogo comandi

| Operazione                       | Comando                                                      |
| -------------------------------- | ------------------------------------------------------------ |
| Verifica accesso remoto          | `git ls-remote https://github.com/AlexGiov/ag-hsm.git lib-export` |
| Collega il remote                | `git remote add ag-hsm https://github.com/AlexGiov/ag-hsm.git` |
| Collega la cartella (una tantum) | `git subtree add --prefix=src/ag-hsm ag-hsm lib-export --squash` |
| Scarica aggiornamenti            | `git fetch ag-hsm lib-export` + `git subtree pull --prefix=src/ag-hsm ag-hsm lib-export --squash` |
| Push modifiche locali            | `git subtree push --prefix=src/ag-hsm ag-hsm lib-export`     |

# Working on the library: Syncing `main` and `lib-export` (bidirectional)

The following chapter cover library synchronization between `main` branch and the `lib-export` branch. The `main` branch typically contains a tested new version of the library, while tha `lib-export` branch typically contains chagned from the consumer application.

The following chapters rapresent a learning path for the following scenario : **hotfixes committed directly to `origin/lib-export`**, which then need to flow back into `main`, while `main`'s own changes to `mylib/` still need to flow out to `lib-export` — without ever rewriting `lib-export`'s published history (consumers rely on `git subtree add/pull`against it, so rewriting it would break their clones).

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
