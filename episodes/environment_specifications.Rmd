---
title: "Environment specifications"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions

- TODO

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- TODO

::::::::::::::::::::::::::::::::::::::::::::::::

**Semantic versioning** (also known as semver) is a convention for constructing version strings^[See [Semantic Versioning 2.0.0 by Preston-Werner et al.](https://semver.org/)].
There are many rules, but the gist is that versions have three numbers separated by dots (e.g., 1.0.0).
Releases that are backwards-incompatible increment the first number (called the major version), while releases that add new functionality in a backwards-compatible way increment the second number (called the minor version), and bug-fix releases increment the third number (called the patch version).

Semantic versioning is related to reproducibility because it helps us specify flexible operating conditions.
If packages follow Semver strictly, all package constraints between A and B would be of the form "A a.b.c requires B greater than x.y.z but less than w.0.0"^{Indeed, `poetry add foo` adds a constraint on `foo` using the newest version as x.y.z and sets w, quite sensibly, to x + 1.}.
- x represents the oldest public interface that A can tolerate; prior versions would have the wrong interface.
- y represents the oldest x that has all the required functionality that A uses. Prior versions would have the right interface but lack critical functionality.
- z represents the newest bug-fix in x.y that A requires. Prior versions would have the right interface and functionality, but lack a bug-fix that A depends on.
- w is the oldest version of the public interface that breaks A.

Flexible operating conditions are easier for the reproducer to satisfy.
They are also more likely to compose with the operating conditions of other experiments without conflicting.

However, Semver is difficult to follow strictly in practice because the package author may not know what is backwards-incompatible.
Hyrum's law^[See [Hyrum's Law by Wright](https://www.hyrumslaw.com/)] states that "with a sufficient number of users of an API, all observable behaviors of your system will be depended on by somebody."

A facetious example is given in the following XKCD comic:

<img src="//imgs.xkcd.com/comics/workflow.png" title="There are probably children out there holding down spacebar to stay warm in the winter! YOUR UPDATE MURDERS CHILDREN." alt="Workflow" srcset="//imgs.xkcd.com/comics/workflow_2x.png 2x" style="image-orientation:none" />

The application developer thinks of their change as a bug fix, since it prevents the CPU from overheating when the space bar is pressed.
However, this particular user thinks of the same change as backwards-incompatible, since it breaks their workflow that depends specifically on the CPU overheating when the space bar is pressed.
A real-world example of difference of opinion on what constitutes backwards-compatibility comes from Python Cryptography when library authors added a build-dependency on Rust. [Library authors](https://github.com/pyca/cryptography/issues/5771#issuecomment-775861925) considered their change forwards-compatible, since the public API did not change; however some sysadmins said this should have been a [major change](https://github.com/pyca/cryptography/issues/5771#issuecomment-775038889), since upgrading broke their systems.
