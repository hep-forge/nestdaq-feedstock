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

The package version is `head`, matching the rolling upstream-head convention.
The source remains pinned to commit
`eda728718362cc0ee169bea9b111ffc3fda7ca6b` and its SHA256 for reproducible builds.
Updating the packaged source requires updating that commit and checksum and
incrementing the build number. The initial `head` package starts at build 0.
Shared-library run exports pin `head` and its recipe build number (allowing
the platform hash) because `head` is not a semantic ABI version. Python 3.12
is used only to run the CLI smoke checks.
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
The release version is `head`. After merging, create a tag named `head` on the
new `main` commit:

```bash
git switch main
git pull --ff-only origin main
git tag head
git push origin refs/tags/head
```

The canonical workflow's automatic push trigger accepts numeric tags only.
For this nonnumeric version, manually run **Anaconda Build & Upload** from
GitHub Actions and select the **head tag**, not a branch. Its existing
workflow_dispatch entry point accepts tag refs. A branch dispatch is skipped.
The recipe's `extra.release_tags.main` entry keeps `head` eligible as a release
during channel trimming. Neither PR smoke builds nor merging a PR publishes.
Do not substitute `v1.0.0` or the old dated snapshot version.

For a later head rebuild, increment the recipe build number and update the
head tag through the project's retag procedure before dispatching at it.
After AMD64 succeeds, set both variables to `amd64,arm64` and rerun the workflow
at that tag to publish ARM64 too. Branch and PR pushes do not publish packages.
Do not tag before the recipe PR is merged.

For the standard meta-repository sync and maintenance tools, register the
feedstock as `feedstocks/nestdaq-feedstock` in `hep-forge/.github` after merge.
This is a separate meta-repository change. Version-bot registration is optional,
as described in the project rules.

## Install after publication

```bash
conda install -c hep-forge -c conda-forge nestdaq=head
```

## Tests and pull requests

The separate `CLI smoke tests` workflow runs on pull requests and manual dispatch.
It builds the conda package on AMD64 first, then ARM64, and runs the installed
package's recipe tests. It uses read-only repository permissions and does not
upload or publish packages. The canonical hep-forge release workflow is
unchanged. Numeric tag pushes run automatically; the `head` tag uses the manual dispatch described above.

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
