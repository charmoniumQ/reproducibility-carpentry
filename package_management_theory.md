---
title: "Package management theory"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions

- TODO

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- To explain the terms: from-source package manager, binary package manager, single-version package repository, multiple-version package repository, and the diamond dependency problem
- To synthesize the pros/cons of from-binary vs from-source and single-coherent-set vs SAT-solving

::::::::::::::::::::::::::::::::::::::::::::::::

A **package manager** is a program that manages (installs, upgrades, removes) a given target software and the target's software dependencies.

There are several distinguishing features of package managers:
1. whether they install packages by compiling the packages from source or downloading binary files
2. whether they attempt to solve dependency
3. whether they operate on a local or system-wide environment

# From-source or binary

**Binary package managers** install software by downloading pre-compiled files and placing them in certain paths.

**From-source package managers** install software primarily by downloading source code, compiling it, and placing it in certain paths.
However, from-source package managers may optionally use a binary cache, where they can download a pre-compiled binary; the salient difference between from-source with binary cache package managers and binary-only package managers is that the former can always "fall back" on compiling the source when the binaries when the cache can't be used for an arbitrary reason.

This design choice influences the following qualities:

- **Speed**: downloading pre-compiled binaries is often faster (assuming the network is fast enough relative to the slowness of compilation).
  However binary caches speed up from-source package managers in common cases^[Although this may not always work out in practice; if the from-source package manager includes the compiler version and CPU family as the package spec ("key" for the cache), as Spack does (for valid performance and reproducibility reasons), the cache will often miss.].

- **Security**: users of binary package managers implicitly trust the package repository storage/delivery and the compiler stack of the maintainer who compiled the package in the first place.
  However, organizations may audit builds can move trust from the maintainer to the auditor (which may be the end-user).
  From-source package managers implicitly trust the package repository storage/delivery and compiler stack on the user's system.

- **Flexibility**: compilation may to include certain assumptions about the runtime system (e.g., dynamic library RUNPATH) or certain extensions (e.g., `--disable-ipv6`).
  Users of binary package managers are subject to whatever compile-time options the maintainer used.
  They can alleviate this by offering multiple variants of the binary at greater storage cost.
  From-source package managers make it much easier to automatically or manually change compile-time options.

- **Infrastructure cost**: binary packages are expensive to store.
  A binary is specific to a CPU instruction-set architecture (ISA) (e.g., x86 64-bit and ARMv8-A), operating system kernel^[[Special hacks](https://justine.lol/ape.html) allow multi-OS binaries, but these hacks are uncommon and fragile.] (e.g., Linux, MacOS, and Windows), and version of the software.
  Each package manager has a different binary format, be it DEB for APT, RPM for YUM/DNF, Wheels for Pip, etc., so reuse between package managers is rare.
  Meanwhile, the version-controlled source-code is shared by users of all CPU ISAs, all OS kernels, all versions^[If the source-code does not use version-control, it could still use [delta compression](https://en.wikipedia.org/wiki/Delta_encoding) or block-based compression more efficiently than binary equivalents.], and all from-source package managers^[Package-manager specific patches may be stored separately, this is still much less storage cost than storing package-manager specific binaries separately, since the patched source are already delta-compressed (only store the patch) and usually small].

In my opinion, the most important factor is infrastructure cost.
**Storing binaries for every ISA, OS, and software version is expensive, so nobody does it for free forever.**
For example, APT depends on volunteers or organizations to host repositories for free but not forever;
[ftp.debian.org](http://ftp.debian.org/debian/dists/) has nothing older than Debian 10.x (2019 -- expected 2024) at the time of writing.
Software environments based on Debian 9.x (new in 2017) may not be reproducible today.
The same problems exist for Ubuntu, Fedora, CentOS, and even multi-platform binary package managers like Conda.^[TODO: Find examples for other pkg mgrs and make into a details snippet]

See caveats about Docker^[TODO: intra-lesson link]; I will use it here to demonstrate "starting from a clean install and running one command."

```docker
FROM debian:9
RUN apt-get update
# At the time of writing, this Dockerfile will fail at this step.
```

On the other hand, storing the source code is much less expensive, and Software Heritage committed to storing the source code of important open-source infrastructure for free for a long time.^[TODO: find their exact commitment] 

Many software projects not only release the source code, they often allow users to modify the source code.
This makes their software more debuggable, repairable, and extensible; if it breaks, users can fix it themselves.
However, the benefits of open-source are not realized if there is more friction in installing from source than installing from binary.
Users would have to locate the source code, download it, learn its build system, find the package manager's build recipe for it, learn the package manager's packaging system, build the binary package, serve the binary from a package repository, add the repository to their package managers sources list, and install it.
When installing from binaries is the common-case, installing from source may become neglected and flaky.

However, the process of compiling software has its own operating conditions necessary for equivalent-behavior reproducibility^[TODO: link to last lesson] (e.g., "requires GCC 12").
But who compiles the compiler?
The operating conditions of the package manager itself can be thought of as a "trusted computing base".

A **trusted computing base (TCB)** is a term from computer security for a small set of software that security analysts assume correctly implements a certain contract, which is usually kept dead-simple.
They develop guarantees of the form "assuming the TCB is correct to its TCB contract, this high-level software correctly implements this high-level contract".
Package managers think of TCB as a small set of software that is "trusted to be reproducible" rather than "trusted to be secure".
As in computer security, package managers should strive to keep their TCB as easy to reproduce as possible, either by making it small or making a good installer that enforces the operating conditions.
^[TODO: How does Spack compile the compiler? What about Nix? What about Guix?]

One may try to pre-compile binary packages for all relevant platforms, but one simply can't predict what ISAs their users will have in the future.
The set of popular ISAs is in constant flux:
- [Itanium](https://en.wikipedia.org/wiki/Itanium) (2001 -- 2021) processors are no longer purchasable
- [SPARC](https://www.wikiwand.com/en/SPARC) (1987 -- 2029 expected) is planned to go that way too
- [PowerPC](https://en.wikipedia.org/wiki/Power_ISA) (2006) is exceedingly rare for desktop consumers at the time of writing
- [x86 64-bit](https://en.wikipedia.org/wiki/X86-64) (2000) and [ARMv8-A](https://en.wikipedia.org/wiki/ARM_architecture_family#64/32-bit_architecture) (2011) have soared (for ARM, due to the popularity of the Raspberry Pi and Apple M-series), with backwards compatibility for [ARMv7-A](https://en.wikipedia.org/wiki/ARM_architecture_family#32-bit_architecture) (2007) and [x86 32-bit](https://en.wikipedia.org/wiki/X86) (1985)
- But even the hegemony of x86-64 is not certain, given Intel's proposed [x86S](https://en.wikipedia.org/wiki/X86-64) (2023).

For these reasons, I suggest using a from-source package manager for long-term reproducibility.

TODO: table

# Dependency Constraint solving or not

Every package has a **version**, which are ordered in sequence^[For example, Spack uses [this total order](https://github.com/spack/spack/blob/e0c6cca65cd001f1e28beac87318dfb605fab22a/lib/spack/docs/packaging_guide.rst#version-comparison), Java uses [this one](https://docs.oracle.com/javase/9/docs/api/java/lang/module/ModuleDescriptor.Version.html), Python uses [this one](https://peps.python.org/pep-0440/), Maven uses [this one](https://docs.oracle.com/middleware/1212/core/MAVEN/maven_version.htm).].

A **dependency constraint** occurs when operating some versions of A requires operating B (operate usually means compile or run).
Since the packages have multiple versions, each version of A may depend on having one of a set of versions of B.
Some versions of A may not depend on B at all, but so long as other versions of A do, we will say A has a dependency constraint on B.
Usually, dependency constraints map a range of versions of A to a range of versions of B, where a range is an upper- and lower-bound, but there can be .
E.g., (Numba 0.58 requires Python at least 3.8 and at most 3.11; Numba 0.55 requires Python at least 3.7 and at most 3.10; ...).
If the dependency constraint is violated, operating the package invokes undefined behavior.

A **Diamond dependency** is a set of packages and dependency constraints where A depends on B and C, B and C depend on D, and the user wants to install A^[Note, this can occur with three packages if the user wants to install B and C; in that case we could pretend the user wanted to install a "virtual package" A, that depends on B and C, so the three-package case is reducible to the four-package case].

<!-- TODO: figure -->

A **consistent set** is a mapping from packages to versions, satisfying dependency constraints.

**Dependency constraint solving** is the process of finding a consistent set.
If the user asks for Python and Numba, package version resolution may select Numba==0.58 and Python==3.11.

Dependency constraint solving for a diamond dependency is particularly tricky.
If one selects a candidate for A (perhaps defaulting to the latest), and then selects compatible candidates for B and C. However, those candidate versions of B and C may require different versions of D.
One may try different candidates for B and C that are compatible with our selected candidate for A, but perhaps none of these will work.
In that case, one has to "backtrack" even further and select a new candidate for A.
A itself may have been the downstream package of another diamond dependency, so one may have to backtrack on those candidates, and so on.

In general, dependency constraint solving is NP-complete^[For a formal proof, see [Dependency Solving: a Separate Concern in Component Evolution Management by Abate et al. in the Journal of Systems and Software 2012](https://www.sciencedirect.com/science/article/abs/pii/S0164121212000477); for an informal proof, see [Version SAT by Cox on their blog 2016](https://research.swtch.com/version-sat)] due to the necessity of backtracking in diamond dependencies.
Oversimplify the details, NP-completeness means the runtime of the fastest known^[If P ≠ NP, then "fastest known" can be replaced with "fastest possible". Computer scientists have been looking for fast algorithms to NP-complete problems for decades; so far no luck. 88% of researchers polled (informally) to respond that P ≠ NP (see [Guest Column: The Third P =? NP Poll by Gasarch in SIGACT News Complexity Theory Column 100 (2019)](https://www.cs.umd.edu/users/gasarch/BLOGPAPERS/pollpaper3.pdf)).] algorithm scales exponentially^[Mathematically astute readers will note this should read "[super-polynomial](https://en.wikipedia.org/wiki/Time_complexity#Superpolynomial_time)" not "exponential", but I did promise to "oversimplify the details" for a general audience.] with the input.

Dependency constraint solving is often implemented as a call to an external [boolean satisfiability (SAT) solver](https://www.wikiwand.com/en/SAT_solver)).
Since they are used in many problems, SAT solvers have been optimized for decades; their runtime is still exponential but a lesser exponential than home-built solutions.

<!-- Slow dependency solving is particularly a pain point for Conda users^[See [conda/conda#7239 on GitHub](https://github.com/conda/conda/issues/7239)]. -->
<!-- [Mamba](https://mamba.readthedocs.io/en/latest/index.html) is a drop-in replcaement for Conda that uses a faster dependency constraint solver, called [libsolv](https://github.com/openSUSE/libsolv). -->
<!-- Conda introduced an experimental option to use Mamba's wrapper around libsolv^[See [A Faster Solver for Conda: Libmamba on Anaconda's blog 2016](https://www.anaconda.com/blog/a-faster-conda-for-a-growing-community)]. -->

Some package managers attempt to reduce the complexity of solving by the following strategies:

- Reducing the number of candidate versions by using fewer package repositories ([Conda's strict package priority](https://docs.conda.io/projects/conda/en/latest/user-guide/concepts/conda-performance.html#set-strict-channel-priority) and [Conda meta-channel](https://medium.com/@marius.v.niekerk/conda-metachannel-f962241c9437)).

- Ordering the candidates such that the correct solve is found earlier ([reordering Conda channels](https://stackoverflow.com/a/66963979/1078199)).

- NodeJS has a notion of "public dependencies" (called "[peer dependencies](https://nodejs.org/en/blog/npm/peer-dependencies)" to NodeJS developers) and "private dependencies" (called "dependencies" to NodeJS developers).
  Private dependencies don't need to be consistent with each other, so the more dependencies that can be treated as private dependencies rather than public dependencies the simpler the dependency graph becomes.
  When B and C privately depend on D, `require("D")` from B can loads a different version than `require("D")` from C (see [Understanding the npm dependency model by King on their blog 2016](https://lexi-lambda.github.io/blog/2016/08/24/understanding-the-npm-dependency-model/)).
  However, if types or global variables from one package end up in the public interface of another, it has to be a public dependency.

  Nix can also make dependencies "private" in some cases.
  If B and C require D to be on the `$PATH`, Nix can replace B with a [wrapper script](https://nixos.org/manual/nixpkgs/stable/#fun-makeWrapper) that adds a specific version of D to the `$PATH` and executes the underlying B program, and likewise for C.
  No copy of D needs to be on the global `$PATH`; the right version of D is always put on the `$PATH` "just in time" for execution of B or C, and the version of D for B does not interfere with the version of D for C.

- Package repositories contain few or only one version of each package (APT/apt-get).
  This reduces the number of candidates to search through.
  However, the community has to ensure that a the repository contains a consistent set for every set of packages.

Therefore, some package managers avoid the package version resolution altogether using one of the following strategies.

- Let the user solve dependency constraints themselves (e.g., Pip before version 20.3).
  This is only practical when the version constraints are loose; i.e., the newest version of A will work with any new-ish version of B.

- Only allow a single version of every package from a manually-maintained consistent set (e.g., [Haskell Stackage](https://www.stackage.org/)).

- [When Maven encounters a diamond dependency](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html), either B or C, whichever is closer to the root, gets its preferred version of D and the other constraint gets ignored.
  The user often specifies the exact version of D themselves to ensure correctness.

|-------------------------------------------------------|-------------------------------------------------------------------|
| Pkg mgrs with dep solv                                | Pip [>= 20.3][pip-backtracking], Conda, Mamba, Spack, 0install    |
| Pkg mgrs with dep solv, limited repos[^limited-repos] | DNF, YUM, APT                                                     |
| Pkg mgrs with no dep solv                             | Nix, Guix, Pacman, Maven, Pip < 20.3                              |

[pip-backtracking]: https://pip.pypa.io/en/stable/topics/dependency-resolution/#backtracking

[^limited-repos]: DNF, YUM, and APT technically do dependency solving, but their package repositories often have just one version of a package dependency. Usually, only a handful of repositories are enabled. These package managers _can_ do dependency solves, but often not efficiently because they rarely encounter large ones.

# Local or system-wide

Package managers either install to a local or a system-wide software environment.

System-wide software environment package managers are necessary for several reasons:

- **Hardcoded paths**:
  Some software uses hardcoded, unchangeable paths to root-owned directories, for example `/usr/lib`.
  Most software today does not have hardcoded paths, and so long as their source code is available and licensed for modifications, it isn't unchangeable.
  Nevertheless, this issue was more important when package managers were designed.^[TODO: Is everything really relocatable?]

- **System-wide effect**:
  Some software has system-level effects or uses, e.g., the bootloader, the kernel, drivers, and login manager are installed using a system-wide package manager.

- **Save space**:
  Historically, disk space was expensive, so system administrators (sysadmins) did not want users compiling the same package just for themselves.
  Rather, the sysadmins installed one for everyone to a global location upon request.

On the other hand, local environment package managers have the following benefits:

- **Reduce dependency conflicts**:
  Suppose project A have conflicting dependencies with project B (unsatisfiable), but if they both have their own local environment, this is no bother.
  Local environments naturally have fewer packages than their system-wide union, minimizing the time needed to SAT-solve.

- **Principle of least privilege**:
  Normal users can manage software environments without superuser privilege.

Containers and virtual machines are one way of using system-wide package managers in a local-environment.

# Conclusion

TODO: APT isn't really snapshottable
We suggest using from-source package managers.
If your application requires specific versions,
local is better
