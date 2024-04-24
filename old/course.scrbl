#lang at-exp racket/base

(require "tags.rkt")

@doc{
  @bibliography["course.bib"]

  @title{How to make reproducible Python environments}

  @abstract{
    Chemistry, astronomy, and other research disciplines increasingly use computational methods. @cite{hettrickSoftwaresavedSoftware_In_Research_Survey_2014Software2018}
    Those researchers have tasks similar to those of a professional software engineer, but they often lack formal software engineering training. @cite{wilsonSoftwareCarpentryLessons2016}
    These researchers are expected to pick up software engineering on the job.
    One of the most difficult aspects of software engineering is writing reproducible programs.
    However, the reproduction of experiments by others is an essential attribute of empirical science. @cite{mertonSociologyScienceTheoretical1974}
    Therefore, we designed this course to explain how to make research reproducible to a research audience.

    We target the Python language due to its popularity in computational science, which itself may be due to its ease-of-use, vibrant package ecosystem, and sufficient performance. @cite{oliphantPythonScientificComputing2007,perezPythonEcosystemScientific2011}
    Like software carpentry @cite{wilson}, we target graduate students; they have time to learn, they write more code, and they may know about the probllems of irreproducibility first-hand.
    Most working graduate students will not have the time to take a multi-session course, so this course is designed to be completed in 90 minutes.
    This course has hands-on exercises for readers because actually invoking commands reinforces memory of the concepts we are teaching. @cite{wilsonSoftwareCarpentryLessons2016}
  }

  @section["Objectives"]{
    @itemlist{
      @item{Give better terminology for discussing reproducibility.}
      @item{Discuss the landscape of methods for reproducible software environments.}
      @item{Recommend a way of constructing reproducible software environments.}
    }
  }

  @section["What is \"reproducibility\"?"]{

    @section{
      @blockquote{
        @{newterm}["Reproducibility"]{
          the ability to obtain a measurement with stated precision by a different team using the same measurement procedure, the same measuring system, under the same operating conditions, in the same or a different location on multiple trials
        }
        @source{acminc.staffArtifactReviewBadging2020}
      }

      Definition comes from metrology ("science of measuring things"), not software-specific.
      We will specialize "measurement", "procedure", "operating conditions" in software context
    }

    @section["Procedure (for software)"]{
      Abstractly: user-interactions required to run the program

      Often, a list of CLI commands, response to prompts (if any), and input data

      @question["Should what the user clicks on while the program is running be considered the procedure?" "Yes"]

      While most programs @emph{should} work for an infinite set of inputs, reproducibility refers to their behavior on just a specific input, perhaps a specific input of scientific interest.
    }

    @section["Measurement (for software)"]{
      @itemlist{
        @item["Error-freedom (program produces result without crashing)"]{easy to assess, but too lenient}
        @item["Bitwise equivalence (outputs same bits)"]{easy to assess, but too strict}
        @item["Statistical equivalence (overlapping confidence intervals, etc.)"]{hard to assess (need domain knowledge), but scientifically meaningful}
        @item["Others"]{domain-specific definitions}
      }
      @question[
        @string{
          What is the relationship between these different measurements? Does acheiveing reproducibility on one of the above measurements guarantee reproducibility on any other?}
        @string{
          Bitwise equivalence implies statistical equivalence, which implies error freedom.
          Error-freedom is not explicitly mentioned in the other two, but since they use the output of a program, they presuppose that the program produces an output without error.
          If the exact bits of two outputs are the same, then their statistical properties should also be the same.
        }
      ]
    }

    @section["Operating conditions (for software)"]{
      @question["soft-env"]{What things do you think should be included in the term software environment?}

      Abstractly: a set of conditions the computer system must implement in order to run a certain program.
      E.g., a POSIX environment, GCC 12 compiled in /usr/bin/gcc with these flags.
      @question{Can your answer to @question-ref{soft-env} be described as abstract conditions for a computer system?}

      Often in UNIX systems, the only relevant conditions are certain objects be on certain "load paths", specified by environment variables.
      E.g., have Python 3.11 in $PATH, have Numpy 1.26 in $PYTHONPATH, and have a blas library in $LIBRARY_PATH.
      It doesn't matter where those programs are on disk, so long as the environment variables are set to point to them.
    }

    @section{
      The ACM further defines the terms repeatability and replicability analagously to reproducibility:

      @blockquote{
        @itemlist{
          @item[(newterm "Repeatability")]{same team, same provedure}
          @item[(newterm "Reproducibility")]{diff team, same procedure}
          @item[(newterm "Replicability")]{diff team, diff procedure}
        }
        @source{acminc.staffArtifactReviewBadging2020}
      }

      Replicability is the holy grail in science, but it is expensive, since a novel measurement procedure (i.e., program) has to be developed.
      The quality of replication depends on "how different" the procedures are (more different is better).
      Instead, we usually shoot for reproducibility.
    }

    @section["More terms"]{
      @itemlist{
        @item[(newterm "Package manager")]{
          Program that can install, update, manage, and remove other programs and their dependencies.
          In particular, the "install" action should identify a compatible set of dependencies.
        }
        @item[(newterm "From-source package manager")]{
          Package manager that installs software by building the software from its source code.
          Note, it may also be able to @emph{optionally} use the pre-built binaries, but it should be able to fall back on building from source.
        }
        @item[(newterm "Binary package manager")]{
          Package manager that installs software by downloading and moving pre-built files.
        }
      }
    }

    @section["Some package manager considerations"]{
      @question[
        @string{Which requires more storage space: binary or from-source package repositories?}
        @string{
          Binary repositories require more storage space.
          One needs to store a binary artifact for every platform and version.
          Binary repositories get only limited reuse from each other, since they often use different formats or assumptions (e.g., RPM binary repository has no ruse with a Debian repository; even a Debian repository and an Ubuntu repository have little reuse, since they are built in totally different environments).

          Source code, on the other hand, does not need separate artifacts for every platform. While there are different artifacts for every version, delta compression and deduplication are effective at reducing their size (version control like Git may use these optimizations automatically).
          There is only one format for source code, i.e., no need for a separate Debian and Ubuntu repository.

          @todo{Cite something for the diff between source and binary storage cost.}
        }
      ]

      @question[
        @string{Which is faster: binary or from-source package managers?}
        @string{Binary package managers. Downloading the binary is often much faster than downloading and building sources. However, from-source package managers may have an optional binary cache, delivering the same speed as binary package managers when the requested package is found in the cache, but still maintaining the flexibility of from-source package managers when it is not.}
      ]


      @question[
        @string{Which is easier to optimize for native architecture: binary or from-source package managers?}
        @string{}
      ]

        @string{
          @itemlist{
            @item{Pro: From-source installation auditable, stack canaries, fsanitize, debug, MUSL.}
            @item{Con: From-source is often slower.}
            @item{Con: From-source compilation can go wrong in more ways.}
          }
        }
      ]
      Why/why not "build from source"?

      What is a "build-time/run-time"?

      What are "dependencies"?

      What is a "diamond dependency"?

      What is "dependency resolution"?

      What is "bootstrapping"?
    }
  }

  @section["References?"]{
    Software Carpentry on git
  }

  @section["How do Python packages work?"]{
    PYTHONPATH

    Venv

    bdist, sdist

    Special case of script entrypoints

    Special case of Jupyter notebooks

    Files (anywhere) + vars (pointing to files) is more general.
  }

  @section["How do system package managers (e.g., `apt-get`, `dnf`, Homebrew, Chocolatey) work?"]{}

  @section["How does setup.py work?"]{
  }

  @section["How does Pip work?"]{
    PyPI

    One arg per line vs all args on one line

    Installing from GitHub

    Building from source
  }

  @section["How do Python build systems work?"]{
    pyproject.toml
  }

  @section["How does Conda work?"]{
    Solves are expensive
    Mamba, Micromamba
    Solves are platform-specific
  }

  @section["How does Spack work?"]{
    Envs

    Concretize
  }

  @section["How does Guix/Nix work?"]{
  }

  @section["How do containers (e.g., Docker, Singularity) work?"]{}

  @section["How do virtual machines (e.g., QEMU, Vagrant, VirtualBox) work?"]{}

  @section["A note on seeds"]{}

  @section["Our recommendations"]{

    Compare to https://the-turing-way.netlify.app/reproducible-research/renv

https://carpentries-incubator.github.io/docker-introduction/

    Compare to https://github.com/activepapers/activepapers-python

    https://carpentries-incubator.github.io/managing-computational-projects/aio.html

    Discuss literate programming

    What is provenance?

  }
}
