# Building and publishing NestDAQ

Conda packaging for [NestDAQ](https://github.com/spadi-alliance/nestdaq)
on the [hep-forge](https://anaconda.org/hep-forge) channel.

## Build

```bash
conda build recipe --override-channels -c hep-forge -c conda-forge
```

The recipe builds NestDAQ against conda packages, including redis-plus-plus
from conda-forge, without rebuilding external projects. Linux AMD64 and ARM64
use native runners through the canonical hep-forge tag workflow. GCC 14 and
glibc 2.17 are pinned; dependency runtime libraries may require a newer GCC
runtime (redis-plus-plus currently requires libstdcxx >=15).

The initial version `2026.10.20` is a dated upstream snapshot pinned to
`eda728718362cc0ee169bea9b111ffc3fda7ca6b`, not upstream's older `v1.0.0` release.
Patches retain Boost.Process v1 compatibility, update Asio APIs, and preserve
conda's portable release flags instead of compiling with `-march=native`.

Redis server and Redis Stack modules remain separate runtime services.

## Publication after merge

Configure `ANACONDA_COMPILE=amd64` and `ANACONDA_PUBLISH=amd64` for an AMD-first
release. Ensure the repository has access to the `ANACONDA_API_TOKEN` secret.
Push numeric tag `2026.10.20` to trigger the canonical build/upload workflow.
After AMD64 succeeds, set both variables to `amd64,arm64` and rerun the workflow
at that tag to publish ARM64 too. Branch and PR pushes do not publish packages.
Do not tag before the recipe PR is merged.

## Install after publication

```bash
conda install -c hep-forge -c conda-forge nestdaq
```

## Tests and pull requests

The canonical hep-forge workflow runs only for numeric release tags. Opening
or updating a pull request does not start a build or run tests. Manual dispatch
at a branch is skipped; dispatch at a release tag runs the workflow.

Each enabled release build runs conda-build, including the recipe tests:
installed plugin and web asset checks, example executable help commands,
and controller help output/status checks. These are package smoke tests,
not upstream unit tests or Redis integration tests. AMD64 still needs CI
validation; the initial ARM64 conda package passed its recipe tests locally.

The initial ARM64 package was validated before adding the run_exports metadata;
the compliance commit changes metadata and documentation, not application code.
