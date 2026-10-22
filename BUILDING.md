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

There are two kinds of version:

- `head` builds upstream `main` as it is at build time (git source, no checksum).
  hep-bot rebuilds it when upstream `main` moves.
- `2026.10.20` is a pinned snapshot: commit
  `eda728718362cc0ee169bea9b111ffc3fda7ca6b` and the SHA256 of its archive. A new
  snapshot is a new entry in `versions` and `commits` in `recipe/meta.yaml`.

Shared-library run exports pin the version and the recipe build number (allowing
the platform hash), because neither `head` nor a date is a semantic ABI version. Python 3.12
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

Pushing a tag on `main` builds linux-64 and linux-aarch64 and uploads them:

- tag `head`: the current upstream `main`. Move the tag to the tip of `main` to pick up
  recipe changes (`git tag -f head && git push -f origin refs/tags/head`). hep-bot does
  this by itself when upstream `main` moves.
- tag `2026.10.20`: the pinned snapshot. hep-bot pushes this tag on its next run, because
  the recipe carries a version that has no tag yet.

Merging a PR or pushing to `main` publishes nothing. Don't use `v1.0.0`: it's an older
upstream release this recipe doesn't build. The feedstock is registered in
[hep-forge/.github](https://github.com/hep-forge/.github), which renders its CI workflow,
README and AGENTS.md.

## Install after publication

```bash
conda install -c hep-forge -c conda-forge nestdaq              # pinned snapshot
conda install -c hep-forge -c conda-forge nestdaq=head         # upstream main
```

## Tests and pull requests

The separate `CLI smoke tests` workflow runs on pull requests and manual dispatch.
It builds the conda package on AMD64 first, then ARM64, and runs the installed
package's recipe tests. It uses read-only repository permissions and does not
upload or publish packages. It builds the first entry of `versions`, i.e. `head`.

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
