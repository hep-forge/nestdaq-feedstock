# Building and publishing NestDAQ

Conda packaging for [NestDAQ](https://github.com/spadi-alliance/nestdaq) on the
[hep-forge](https://anaconda.org/hep-forge) channel. One package, built in this order
(`recipe/build.sh`):

1. **nestdaq**: FairMQ plugins, example devices and the web controller (`daq-webctl`).
2. **uhbook**: header-only booking tool, installed to `include/uhbook/`.
3. **[nestdaq-user-impl](https://github.com/spadi-alliance/nestdaq-user-impl)** on top,
   into the same prefix as upstream installs it: Sampler, Sink, FileSink, STFBuilder,
   TimeFrameBuilder, the TimeFrame filters, LogicFilter, TriggerView, Scaler, tfdump,
   emulator, AmQStrTdcSampler, ... Its `Sampler` and `Sink` replace the nestdaq
   examples of the same name.

ROOT 6.38 and ROOT+ (`root-plus`) come from hep-forge. The build string is the ROOT line
(`root638`), as for rapgap and xfitter. Redis server and Redis Stack modules are separate
runtime services.

## Build

```bash
conda-build recipe --override-channels -c hep-forge -c conda-forge
```

GCC 14 and glibc 2.17 are pinned in `recipe/conda_build_config.yaml`. Python 3.12 is
only used to run the CLI smoke checks.

## Versions

Every version includes nestdaq-user-impl and uhbook.

- `head` builds the latest upstream commit of nestdaq, nestdaq-user-impl and uhbook.
  hep-bot rebuilds it each time a new nestdaq commit arrives.
- `1.0.0` builds the upstream tags `v1.0.0` of nestdaq and nestdaq-user-impl, with the
  last uhbook commit before them (`e979eb2`). A later release `X.Y.Z` maps to the tags
  `vX.Y.Z` by default; list it in `versions`, `user_impl` and `uhbook` if it needs other
  refs.

## Patches

`recipe/patches/nestdaq/`: Boost.Process v1 compatibility and current Asio APIs, conda's
release flags instead of `-march=native` (`-1.0.0` variant for the older layout), for
1.0.0 the FairMQ >= 1.8 check backported from upstream `main`,
`--help` exiting 0 before the controller starts, and the controller's Redis library
found with `find_library`.

`recipe/patches/user-impl/conda-build.patch` (`head`) and `conda-build-1.0.0.patch`:
accept this channel's FairMQ 1.11 (upstream `v1.0.0` stops at 1.8.x and misses the
`<fairmq/Transports.h>` include fixed on `main`; `main` stops at 1.10.0
and at 1.8 in LogicFilter and TriggerView), no `-march=native`, every executable
installed to `bin/`, and the internal static libraries (Utility, bundled sqlite,
AmQTdcModule) linked but not installed.

## Publication

Pushing a tag on `main` builds linux-64 and linux-aarch64 and uploads them:

- `head`: the latest upstream commit. hep-bot moves the tag to the tip of `main` (and so
  rebuilds) whenever upstream nestdaq gets a new commit. To pick up a recipe change
  right away: `git tag -f head && git push -f origin refs/tags/head`.
- `1.0.0`: upstream `v1.0.0`. hep-bot pushes this tag on its next run, because the
  recipe has that version without a tag.

Merging a PR or pushing to `main` publishes nothing.

```bash
conda install -c hep-forge -c conda-forge nestdaq              # latest release (1.0.0)
conda install -c hep-forge -c conda-forge nestdaq=head         # latest upstream commit
```

## Tests

The `CLI smoke tests` workflow builds the package on pull requests (AMD64, then ARM64)
and runs the recipe tests; it never uploads. It builds the first entry of `versions`,
`head`; build `1.0.0` locally with `COMMIT_VERSION=1.0.0 conda-build recipe ...`. The tests check the nestdaq plugins and web
assets, the user-impl executables and the uhbook headers, and run
`recipe/run_cli_smoke.py`: `--help` of Sampler, Sink and NullDevice, and the controller's
help and argument errors, without starting Redis or the web server. To run the CLI
checks against an installed package:

```bash
conda run -n nestdaq python recipe/run_cli_smoke.py
```
