# Building and publishing NestDAQ

Conda packaging for [NestDAQ](https://github.com/spadi-alliance/nestdaq)
on the [hep-forge](https://anaconda.org/hep-forge) channel.

## Build

```bash
conda-build recipe --override-channels -c hep-forge -c conda-forge
```

The recipe builds NestDAQ against conda packages, including redis-plus-plus
from conda-forge, without rebuilding external projects. Linux AMD64 and ARM64
use native runners through the canonical hep-forge tag workflow. GCC 14 and
glibc 2.17 are pinned; dependency runtime libraries may require a newer GCC
runtime (redis-plus-plus currently requires libstdcxx >=15).

The initial version `2026.10.20` is a dated upstream snapshot pinned to
`eda728718362cc0ee169bea9b111ffc3fda7ca6b`, not upstream's older `v1.0.0` release.
Patches retain Boost.Process v1 compatibility, update Asio APIs, copy WebSocket
binary payloads through `buffer_copy`, locate the controller Redis library with
`find_library`, and preserve conda's portable release flags instead of compiling
with `-march=native`.

Redis server and Redis Stack modules remain separate runtime services.

## Supported platforms

This recipe supports Linux AMD64 (`linux-64`) and Linux ARM64
(`linux-aarch64`). Native macOS (`osx-64`, `osx-arm64`) builds are skipped.
A Linux container on macOS can use the matching Linux package after publication;
changing conda's platform alone does not make Linux binaries run on macOS.

## Publication after merge

Configure `ANACONDA_COMPILE=amd64` and `ANACONDA_PUBLISH=amd64` for an AMD-first
release. Ensure the repository has access to the `ANACONDA_API_TOKEN` secret.
The supported release version is `2026.10.20` (recipe build 2). After merging,
create that numeric tag on the new `main` commit to trigger the canonical
build/upload workflow. Merging a PR or running CLI smoke CI does not publish.

```bash
git switch main
git pull --ff-only origin main
git tag 2026.10.20
git push origin refs/tags/2026.10.20
```

Do not substitute `1.0.0`: the recipe's version/checksum mapping currently
contains only the dated source snapshot. If the release tag already exists,
use the meta-repository's documented `make retag nestdaq` procedure to rebuild
the current recipe rather than silently building an old tag's recipe.
After AMD64 succeeds, set both variables to `amd64,arm64` and rerun the workflow
at that tag to publish ARM64 too. Branch and PR pushes do not publish packages.
Do not tag before the recipe PR is merged.

For the standard meta-repository sync and maintenance tools, register the
feedstock as `feedstocks/nestdaq-feedstock` in `hep-forge/.github` after merge.
This is a separate meta-repository change. Version-bot registration is optional,
as described in the project rules.

## Install after publication

```bash
conda install -c hep-forge -c conda-forge nestdaq
```

## Tests and pull requests

The separate `CLI smoke tests` workflow runs on pull requests and manual dispatch.
It builds the conda package on AMD64 first, then ARM64, and runs the installed
package's recipe tests. It uses read-only repository permissions and does not
upload or publish packages. The canonical hep-forge release workflow is unchanged
and still runs only at numeric release tags.

Recipe tests check installed plugins and web assets plus seven CLI cases:
`Sampler`, `Sink`, and `NullDevice` help, both controller help flags, an unknown
controller option, and a missing option value. Each CLI invocation has a 15-second
timeout. Help must return zero without starting Redis or the web server; invalid
arguments must return one with a useful diagnostic. The CLI help patch ensures
normal help exits successfully before controller service initialization.

These are package smoke tests, not Redis integration or upstream unit tests.
To run them against an already installed package:

```bash
conda run -n nestdaq python recipe/run_cli_smoke.py
```

For a full package build including these tests, use the build command above.
