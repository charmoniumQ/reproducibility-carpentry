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

There are several distinguishing features of package managers:
1. whether they attempt to solve dependency constraints or not
2. whether they install packages by compiling the packages from source or by downloading a binary file
3. whether they operate on an environment or whole-system
4. how easily do they permit user-defined packages

# Dependency Constraint solving or not

Every package has a **version**, which are ordered in sequence^[For example, Spack uses [this total order](https://github.com/spack/spack/blob/e0c6cca65cd001f1e28beac87318dfb605fab22a/lib/spack/docs/packaging_guide.rst#version-comparison), Java uses [this one](https://docs.oracle.com/javase/9/docs/api/java/lang/module/ModuleDescriptor.Version.html), Python uses [this one](https://peps.python.org/pep-0440/), Maven uses [this one](https://docs.oracle.com/middleware/1212/core/MAVEN/maven_version.htm).].

A **dependency constraint** occurs when operating some versions of A requires operating B (operate usually means build or run).
Since the packages have multiple versions, each version of A may depend on having one of a set of versions of B.
Some versions of A may not depend on B at all, but so long as other versions of A do, we consider A to have a dependency constraint on B.
Usually, dependency constraints map a range of versions of A to a range of versions of B, where a range is an upper- and lower-bound, but there can be .
E.g., (Numba 0.58 requires Python at least 3.8 and at most 3.11; Numba 0.55 requires Python at least 3.7 and at most 3.10; ...).
If the dependency constraint is violated, operating the package invokes undefined behavior.

A **Diamond dependency** is a set of packages and dependency constraints where A depends on B and C, B and C depend on D, and the user wants to install A^[Note, this can occur with three packages if the user wants to install B and C; in that case we could pretend the user wanted to install a "virtual package" A, that depends on B and C, so the three-package case is reducible to the four-package case].

<!-- TODO: figure -->

A **consistent set** is a mapping from packages to versions, satisfying dependency constraints.

**Dependency constraint solving** is the process of finding a consistent set.
If the user asks for Python and Numba, package version resolution may select Numba==0.58 and Python==3.11.

Dependency constraint solving for a diamond dependency is particularly tricky.
If we select a candidate for A (perhaps defaulting to the latest), and then select compatible candidates for B and C. However, those candidate versions of B and C may require different versions of D.
We may try different candidates for B and C that are compatible with our selected candidate for A, but it is possible none of these work.
In that case, we have to "backtrack" even further and select a new candidate for A.
A itself may have been the downstream package of another diamond dependency, so we may have to backtrack on those candidates, and so on.

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

- NodeJS has a notion of "public dependencies" (called "peer dependencies" to NodeJS developers) and "private dependencies" (called "dependencies" to NodeJS developers).
  When B and C privately depend on D, `require("D")` from B can loads a different version than `require("D")` from C^[See [Peer Dependencies by Denicola on NodeJS blog](https://nodejs.org/en/blog/npm/peer-dependencies) and [Understanding the npm dependency model by King on their blog 2016](https://lexi-lambda.github.io/blog/2016/08/24/understanding-the-npm-dependency-model/)].
  Private dependencies don't need to be consistent with each other, so the more dependencies that can be treated as private dependencies rather than public dependencies the simpler the dependency graph becomes.
  However, if types or global variables from one package end up in the public interface of another, it has to be a public dependency.

  Nix can also make dependencies "private" in some cases.
  If B and C require D to be on the `$PATH`, Nix can replace B with a wrapper script that adds a specific version of D to the `$PATH` and executes the underlying B program, and likewise for C^[See [`makeWrapper` in Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/#fun-makeWrapper)].
  No copy of D needs to be on the global `$PATH`; the right version of D is always put on the `$PATH` "just in time" for execution of B or C, and the version of D for B does not interfere with the version of D for C.

- Package repositories contain very few or only one version of each package (APT/apt-get).
  This reduces the number of candidates to search through.
  However, the community has to ensure that a the repository contains a consistent set for every set of packages.

Therefore, some package managers avoid the package version resolution altogether using one of the following strategies.

- Let the user solve dependency constraints themselves (e.g., Pip before version 20.3).
  This is only practical when the version constraints are loose; i.e., the newest version of A will work with any new-ish version of B.

- Only allow a single version of every package from a manually-maintained consistent set (e.g., [Haskell Stackage](https://www.stackage.org/)).

- Use semantic versioning (semver) and only permit package constraints of the form "greater than x.y.z but less than (x+1).0.0"^[See "Alternatives?" [Version SAT by Cox on their blog 2016](https://research.swtch.com/version-sat)].
  We don't know of any package managers that exploit this to avoid NP-complete dependency constraint solving, but it is an interesting direction.
  We discuss difficulties in using semver later. <!-- TODO link -->

- When Maven encounters a diamond dependency, the package closer to the root (of B or C) gets to have its preferred version of D and the other constraint gets ignored^[See "dependency mediation" in [Introduction to the Dependency Mechanism in Maven's documentation](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html)].
  The user often specifies the exact version of D themselves to ensure correctness.

Package managers that use dependency solvers include Pip [after 20.3](https://pip.pypa.io/en/stable/topics/dependency-resolution/#backtracking), Conda, Mamba, Spack.

DNF, YUM, and APT technically do dependency solving, but their package repositories often have just one version of a package dependency.
Usually, only a handful of repositories are enabled.

Nix, Guix, Pacman, Maven, and Pip before 20.3 do not do dependency solving.
Their repository offers a single version of every package.
However, users can easily override that package to use a different version (see user-defined packages).

# From-source or binary

Software can be installed by downloading pre-built executables include the target environment or {downloading source code and building those executables} in the target environment.

Correlates with user-defined packages

Bootstrapping and TCB

# Environment or whole-system

Correlates with "requires superuser privileges" vs "unprivileged"

# User-defined packages

- Environment specification file can have user packages: Nix, Guix
- Can easily create a local repository: Spack, Pacman <!-- TODO: more research needed -->, Conda?
