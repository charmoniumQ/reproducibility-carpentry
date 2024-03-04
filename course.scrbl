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

  @section["What is reproducibility?"]{
    @itemlist{
      @item{@newterm{Repeatability}}
      @item{@newterm{Reproducibility}}
      @item{@newterm{Replicability}}
    }
  }

  @section["What is the measurement?"]{
    @itemlist{
      @item{Program executes}
      @item{
        Some more detailed property of the results
        @itemlist{
          @item{Statistical equivalence}
          @item{Bitwise equivalence}
        }
      }
    }
  }

  @section["What are software packages?"]{
    What is the "software environment"?

    What is a "software package"? Has versions, source, binary.

    Why/why not "build from source"?

    What is "-march=native"?

    What is a "build-time/run-time"?

    What are "dependencies"?

    What is a "diamond dependency"?

    What is "dependency resolution"?

    What is "bootstrapping"?
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

  @section["Our recommendations"]{

    Compare to https://the-turing-way.netlify.app/reproducible-research/renv

    Compare to https://github.com/activepapers/activepapers-python
  }

}
