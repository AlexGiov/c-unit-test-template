# C Library Directory Organization

## Objective

This document outlines a professional structure for organizing a reusable C library, clearly separating:

- Public API
- Private implementation
- Configuration
- Tests and examples

The goal is to make the library:

- Self-contained within its own repository
- Easy to integrate into an application project

- Simple to version
- Clear to maintain over time

---

## How this template applies it

In this repository the library root is `mylib/` (not the repository root itself),
using `inc/` instead of `include/` as the public-header directory name. Unlike
the `logger/` example below, the header lives directly under `inc/` (no extra
namespace subfolder in the source tree - `mylib/` itself already plays that role):

```text
mylib/
├─ inc/
│  └─ mylib.h
├─ src/
│  └─ mylib.c
├─ config/
│  └─ mylib_config.h.template
└─ CMakeLists.txt
```

`mylib/` is a fixed folder name, kept stable across renames of the library
itself (`project()` name, `inc/<name>.h`, `src/<name>.c`): it is the exact
prefix used by `git subtree split --prefix=mylib` to export the library into
its own branch/repository, so its structure and location must stay predictable.
The dev-only `cfg/` (real, non-template configuration) and `test/` stay outside
`mylib/`, at the repository root, per the "Configuration: Template in Library,
Actual File in App" rule below.

---

## Recommended Structure

```text
logger/
├─ include/
│  └─ logger/
│     └─ logger.h
├─ src/
│  ├─ logger.c
│  └─ logger_internal.h
├─ config/
│  └─ logger_config.h.template
└─ README.md
```

This structure is suitable for a C library maintained in a separate repository and linked to the application project as a versioned dependency.

---

## Directory Meanings

### `include/`

This is the root of the library's **public headers**.

It contains no implementation, only what must be visible externally.

For the `logger` library:

```text
include/
└─ logger/
   └─ logger.h
```

This allows the application to include the public API in an organized way:

```c
#include <logger/logger.h>
```

### Why use `include/logger/` instead of putting `logger.h` directly in `include/`

Using a subfolder with the library name provides a clear namespace and reduces the risk of collisions with other libraries.

Correct example:

```text
include/logger/logger.h
```

Less robust example:

```text
include/logger.h
```

The first form is preferable in professional and scalable libraries.

---

### `src/`

Contains the library implementation.

Example:

```text
src/
├─ logger.c
└─ logger_internal.h
```

This should contain:

- `.c` files
- Private headers
- Internal data structures
- Static functions or implementation details

Headers in `src/` **must not be included by the application**.

---

### `config/`

Contains the **template** of the configuration file, not the file actually used in compilation by the application.

Example:

```text
config/logger_config.h.template
```

The template serves as:

- Documentation of available options
- Configuration example
- Base to copy into the application project

The actual configuration file should be in the application repository, for example:

```text
cfg/logger_config.h
```

In the library code, it's best to always include the stable logical name:

```c
#include "logger_config.h"
```

The application's build system will ensure the correct file in `cfg/` is found.



### `README.md`

Should concisely describe:

- Library purpose
- Dependencies
- Integration methods
- Required configuration
- Usage example

---

## Separation Between Public and Private

A fundamental best practice is to clearly separate:

### Public API

Goes in `include/logger/`.

Only these should go here:

- Public prototypes
- Public types
- Public enums
- Macros strictly for the interface

### Private Implementation

Goes in `src/`.

These should go here:

- Internal structures
- Support functions
- Details hidden from the user
- Internal headers like `logger_internal.h`

This separation prevents the application from depending on details that might change.

---

## Configuration: Template in Library, Actual File in App

In the discussed case, the library lives in a dedicated repository and is linked to the application project as an external dependency.

In this scenario, it's correct that:

- The library repository contains only the configuration template
- The application project contains the actual configuration

### Example

In the library repo:

```text
logger/
└─ config/
   └─ logger_config.h.template
```

In the application repo:

```text
app_project/
└─ cfg/
   └─ logger_config.h
```

This way:

- The library is not modified directly in the application project
- The configuration remains under the application's control
- Updating the library is simpler

---

## Library in Separate Repository

If the library is maintained in an autonomous repository, it's preferable that the `include/` folder also stays **inside** the library.

Correct example:

```text
logger/
├─ include/
├─ src/
├─ config/
└─ tests/
```

This choice offers concrete advantages:

- The library is self-sufficient
- Can be tested in isolation
- Can be reused in other projects without changing structure
- The public API is clearly identified

---

## Why Not Use a Shared `include/` Outside the Library

A shared `include/` at the project level can make sense in a single monorepo, for example:

```text
project/
├─ include/
├─ libs/
└─ app/
```

but in the case of a library in a separate repository, it's less suitable because it makes the library less autonomous.

For an independent library, it's cleaner to keep all public content under its own directory.

---

## Recommended Include Convention

With this structure, the application project adds to the include paths:

```text
.../logger/include
.../cfg
```

and includes the public header like this:

```c
#include <logger/logger.h>
```

while the library includes the configuration like this:

```c
#include "logger_config.h"
```

---

## Final Practical Example

### Library Repository

```text
logger/
├─ include/
│  └─ logger/
│     ├─ logger.h
│     ├─ logger_types.h
│     └─ logger_version.h
├─ src/
│  ├─ logger.c
│  └─ logger_internal.h
├─ config/
│  └─ logger_config.h.template
├─ tests/
│  └─ test_logger.c
├─ examples/
│  └─ basic_example.c
└─ README.md
```

### Application Repository

```text
app_project/
├─ app/
├─ cfg/
│  └─ logger_config.h
├─ external/
│  └─ logger/
└─ build/
```

---

## Final Practical Rules

1. Put only public headers in `include/`.
2. Put implementation and private headers in `src/`.
3. Put only templates or configuration documentation in `config/`.
4. Keep the actual configuration file in the application project.
5. Use a namespace subfolder under `include/`, for example `include/logger/`.
6. Never expose internal headers to the application.
7. Keep the library self-sufficient in its own repository.

---

## Conclusion

The recommended structure for a professional C library is:

```text
logger/
├─ include/
│  └─ logger/
│     └─ logger.h
├─ src/
│  ├─ logger.c
│  └─ logger_internal.h
├─ config/
│  └─ logger_config.h.template
└─ README.md
```

This is a solid, readable structure suitable for professional development, especially when the library lives in a dedicated repository and is integrated into the application as a versioned external dependency.
