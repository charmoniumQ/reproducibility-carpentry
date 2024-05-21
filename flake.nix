{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      rec {
        packages = rec {
          varnish = pkgs.rPackages.buildRPackage {
            name = "varnish";
            src = pkgs.fetchFromGitHub {
              owner = "carpentries";
              repo = "varnish";
              rev = "9d98f8ca03c0c0ff0d0f20e75e92eae4d08968d8";
              hash = "sha256-TyMJs/NS0bZPbj9ciK7tIJSfkqBzxMpT9eDvr2+PXyw=";
            };
            propagatedBuildInputs = [ ];
          };
          pegboard = pkgs.rPackages.buildRPackage {
            name = "pegboard";
            src = pkgs.fetchFromGitHub {
              owner = "carpentries";
              repo = "pegboard";
              rev = "a32a7836d4455f407c3cafe8ab95edc636e5e919";
              hash = "sha256-EHv6rx3ER8iVAaklnYzISMcgxyPDErj1vfRFY4z6hIY=";
            };
            propagatedBuildInputs = with pkgs.rPackages; [
              commonmark
              fs
              glue
              purrr
              R6
              tinkr
              xml2
              xslt
              yaml
              cli
              covr
              crayon
              dplyr
              gert
              here
              knitr
              magrittr
              rlang
              rmarkdown
              testthat
              withr
            ];
          };
          sandpaper = pkgs.rPackages.buildRPackage {
            name = "sandpaper";
            src = pkgs.fetchFromGitHub {
              owner = "carpentries";
              repo = "sandpaper";
              rev = "415d3b97b64cc42b43d3f3cddebe744ed349bea9";
              hash = "sha256-59z+OzSSETeN/Ug41UyX1R6aSgUkThRNw8LD7Ifkm0M=";
            };
            propagatedBuildInputs = with pkgs.rPackages; [
              pkgdown
              pegboard
              cli
              commonmark
              fs
              gh
              gert
              rstudioapi
              rlang
              glue
              assertthat
              yaml
              desc
              knitr
              rmarkdown
              renv
              rprojroot
              usethis
              withr
              whisker
              callr
              servr
              # utils
              # tools
              testthat
              covr
              markdown
              brio
              xml2
              xslt
              jsonlite
              sessioninfo
              mockr
              varnish
            ];
          };
          newer-snakemake = pkgs.snakemake.overrideAttrs (self: super: rec {
            version = "8.11.6";
            pname = "snakemake";
            src = pkgs.fetchFromGitHub {
              owner = "snakemake";
              repo = pname;
              rev = "refs/tags/v${version}";
              hash = "sha256-00Zh8NenBikdingmx34WYYH5SF+yazeAs+7h1/3UIJY=";
              # https://github.com/python-versioneer/python-versioneer/issues/217
              postFetch = ''
                sed -i "$out"/snakemake/_version.py -e 's#git_refnames = ".*"#git_refnames = " (tag: v${version})"#'
              '';
            };
          });
        };
        devShells = {
          sandpaper = pkgs.mkShell {
            buildInputs = [
              pkgs.texlive.combined.scheme-full
              pkgs.pandoc
              pkgs.gitFull
              pkgs.R
              packages.sandpaper
              packages.varnish
              packages.pegboard
              pkgs.rPackages.tinkr
              pkgs.rstudio
            ];
            shellHook = ''
              alias R='R --no-restore --no-save'
            '';
          };
          snakemake = pkgs.mkShell {
            buildInputs = [
              pkgs.graphviz
              pkgs.xdot
              (pkgs.python312.withPackages(ps: [ ps.pyyaml packages.newer-snakemake ]))
            ];
          };
        };
      }
    )
  ;
}
