---
title: "Reproducibility definition"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions

- Define reproducibility.
- What are various kinds or degrees of reproducibility?
- Why are Jupyter and Knitr notebooks not sufficient by themselves for reproducibility?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- To articulate the definition of reproducibility in the domain of computational science.
- To assess the kind of reproducibility offered by tools you already know of.

::::::::::::::::::::::::::::::::::::::::::::::::

# Definitions

**Reproducibility** [according to the ACM](https://www.acm.org/publications/policies/artifact-review-and-badging-current) means: the ability to obtain a measurement with stated precision by a different team using the same measurement procedure, the same measuring system, under the same operating conditions, in the same or a different location on multiple trials.

This definition derives from _metrology_, the science of measuring, and we will specialize some of the terms "measurement", "measurement procedure", and "operating conditions" in software context for computational science experiments (from here on, **CSEs**).

**Measurement procedure (for CSEs)**: the application code and user-interactions required to run the application code (if any).

**Operating conditions (for CSEs)**: a set of conditions the computer system must implement in order to run a certain program.
E.g., a POSIX environment, GCC 12 compiled in `/usr/bin/gcc` with these flags.

For every CSE, there are probably some operating conditions in which it is the measurement can be made.
To make our definition not vacuous, "reproducibility" will require all relevant operating conditions have to be documented (e.g., "README.md states you must have GCC 12 in `/usr/bin/gcc`").
Operating conditions can be eliminated by moving them to the measurement procedure (e.g., the program itself contains a copy of GCC 12).
For the purposes of this lesson, the operating conditions are the "manual" steps that the user has to take in order to use the measurement procedure to make the measurement.
One may over-specify operating conditions without changing the reproducibility status (e.g., one might say their software requires GCC 12, but really GCC 13 would work); it is quite difficult and often not necessary to know the minimal set of operating conditions, so in practice, we usually have an larger-than-necessary set of operating conditions.

Often in UNIX-like systems, the only relevant conditions are certain objects be on certain "load paths", specified by environment variables.
E.g., have Python 3.11 in `$PATH`, have Numpy 1.26 in `$PYTHONPATH`, and have a BLAS library in `$LIBRARY_PATH`.
In such cases, it doesn't matter where those programs are on disk; the only relevant "operating condition" is that the environment variables are set to point to those programs at a compatible version.

**Measurement (for CSEs)**:

- Crash-freedom: program produces result without crashing.
- Bitwise equivalence: output files and streams are identical.
- Statistical equivalence: overlapping confidence intervals, etc.
- Inferential equivalence: whether the inference is supported by the output.
- Others: domain-specific measurements/equivalences (e.g., XML-equivalence ignores order of attribtues)

In general, it is difficult to find a measurement that is both easy to assess and scientifically meaningful.

| Measurement             | Easy to assess                             | Scientifically meaningful                                     |
|-------------------------|--------------------------------------------|---------------------------------------------------------------|
| Crash-freedom           | Yes; does it crash?                        | Too lenient; could be no-crash but completely opposite result |
| Bitwise equivalence     | Yes                                        | Too strict; could be off by one decimal point                 |
| Statistical equivalence | Maybe; need to know output format          | Maybe; need to know which statistics _can_ be off             |
| Inferential equivalence | No; need domain experts to argue about it  | Yes                                                           |

We explicitly define reproducibility because not everyone uses the ACM definition.
[Reproducible Builds](https://reproducible-builds.org/docs/definition/) and [Google's Building Secure and Reliable Systems](https://google.github.io/building-secure-and-reliable-systems/raw/ch14.html#hermeticcomma_reproduciblecomma_or_veri) uses bit-wise equivalence only.
Operating on different definitions without realizing it leads to [disagreements](https://linderud.dev/blog/nixos-is-not-reproducible/).
Defining reproducibility with respect to a measurement and operating conditions is more useful; one can refer to different kinds and degrees of reproducibility in different conditions.

**Composition of measurement procedures**: The outcome of one measurement may be the input to another measurement procedure.
This can happen in CSEs as well as in physical experiments.
In physical experiments, one may use a device to calibrate (measure) some other device, and use that other device to measure some scientific phenomenon.
Likewise, In CSE, the output of compilation may be used as the input to another CSE.
One can measure a number of relevant properties of the result of a software compilation.

| Compilation measurement            | Definition                                                       |
|------------------------------------|------------------------------------------------------------------|
| Source equivalence                 | Compilation used exactly this set of source code as input        |
| Behavioral equivalence             | The resulting binary has the same behavior as some other one     |
| Bit-wise equivalence               | As before, the binary is exactly the same as some other one      |

E.g., suppose one runs `gcc main.c` on two systems and one system uses a different version of `unistd.h`, which is `#included` by `main.c`.
The process (running `gcc main.c`) does not reproduce source-equivalent binaries, but it might reproduce behavior-equivalent binaries or bit-wise equivalent binaries (depending on how different `unistd.h`).

# Related terms

**Replicability** and **repeatability** are similar to reproducibility, with the only difference whether the team is the same or different than the original and whether the measurement procedure is the same or different as the original.

| Term            | Team | M. Proc | Example                                                                                          |
|-----------------|------|---------|--------------------------------------------------------------------------------------------------|
| Repeatability   | Same | Same    | I can run ./script twice and get the same result                                                 |
| Reproducibility | Diff | Same    | ./script on my machine and ./script on your machine give the same result                         |
| Replicability   | Diff | Diff    | ./script and a new script that you wrote for the same task on your machine give the same result  |

Replicability is of course the goal of scientific experiments, because the measurement can be made in different ways but still give consistent results.
However, replicability involves re-doing some or all of the work, so it is expensive to pursue in practice.
Therefore, we examine repeatability and reproducibility instead.

**Computational provenance** is a record of the process by which a particular computational artifact was generated (**retrospective**) or could potentially be generated (**prospective**)^[See [Provenance for Computational Tasks: A Survey by Friere et al. in Computing in Science & Engineering 2008](https://collections.lib.utah.edu/dl_files/50/a0/50a096638d7465e69a5ba0151da9a71918ecfd50.pdf)].
Provenance of a final artifact may include the provenance of the artifacts used by the final process, and so on, the artifacts used to generate the artifacts used to generate (and so on...) the final artifact.

Provenance is related to reproducibility because sufficiently detailed provenance (prospective or retrospective) may allow other users to reproduce the process within some equivalence.

Although there are many definitions of **computational workflows**, the most related definition is a program written in a language that explicitly represents a loosely-coupled, coarse-grained dataflow graph.
"Loosely-coupled" and "coarse-grained" has some wiggle room, but usually each node represents an isolated process or container and the edges are usually files or parameters, for example, GNU Make and [Snakemake](https://snakemake.readthedocs.io/en/stable/).
Workflows improve reproducibility by automating manual commands thereby documenting the measurement procedure for others.
Often workflows are the alternative to projects which previously run a pile of scripts in a specific order known only to the developers.
Workflows can be seen as a form prospective provenance and workflow engines are a natural place to emit prospective and retrospective provenance.
Workflows are not necessary for reproducibility, so long as the relevant measurement procedure is otherwise documented or automated, and they are sufficient only when the workflow language is sufficiently detailed (i.e., detailed enough to capture all of the relevant operating conditions).

**Literate programming** is a medium where a program's source code is embedded in an explanation of how it works^[See [Literate Programming by Knuth in The Computer Journal 1984](https://doi.org/10.1093/comjnl/27.2.97)].
Systems that facilitating literate programming (from here on, **literate programming systems**) often also permit the user to execute snippets of their code and embed the result automatically in a report.
Programs written in literate programming systems with cell execution used in data science are sometimes called "notebooks", due to their resemblance to a lab notebook.
[Jupyter](https://jupyter.org/), [Knitr](https://yihui.org/knitr/), and [Quarto](https://quarto.org/) are examples of literate programming system with cell execution.
These are often discussed in the context of reproducibility (See [1](https://doi.org/10.1038/515151a), [2](https://doi.org/10.1038/d41586-018-07196-1), [3](https://www.taylorfrancis.com/chapters/edit/10.1201/9781315373461-1/knitr-comprehensive-tool-reproducible-research-yihui-xie), [4](https://doi.org/10.1201/9781315373461 ), [5](https://doi.org/10.1142/9789814749411_0018)).
Like workflows, notebooks automate procedures that may otherwise be manual (thereby documenting them for others); they can even contain the output of the code, so one can verify if their result is the similar to the authors.
Also like workflows, notebooks are not sufficient by themselves for reproducibility, although they can be a valuable part of a reproducible artifact; there are often necessary operating conditions (must have Numpy version 1.26; must have `data.csv`) that are documented outside of the notebook or not documented at all.
Since notebooks support cell-execution triggered by a UI element, the cells can be executed in a manual order, which becomes an undocumented part of the measurement procedure.

**Containers and virtual machines (VMs)** are related to reproducibility.
These will be discussed in depth in a future episode.

<!-- TODO: Pre-workshop survey -->

<!-- TODO: create a concept map and outline -->

<!-- https://carpentries.org/blog/2016/11/reproducibility-reading-list/ -->
