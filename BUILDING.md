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

ROOT 6.38 and ROOT+ (`root-plus`) come from hep-forge; the build string carries the ROOT
line (`root638_<build>`). Redis server and Redis Stack modules are separate runtime
services.

## Build

```bash
conda-build recipe --override-channels -c hep-forge -c conda-forge
```

GCC 14 and glibc 2.17 are pinned in `recipe/conda_build_config.yaml`. Python 3.12 is
only used to run the CLI smoke checks.

## Versions

- A numeric version (`2026.10.20`) is a pinned snapshot: `versions` gives the nestdaq
  commit, `user_impl` and `uhbook` the commits built on top of it. A new snapshot is one
  new entry in each.
- `head` (any version not listed) builds the upstream `main` of all three. hep-bot
  rebuilds it when upstream nestdaq `main` moves.

## Patches

`recipe/patches/nestdaq/`: Boost.Process v1 compatibility and current Asio APIs, conda's
release flags instead of `-march=native`, `--help` exiting 0 before the controller
starts, and the controller's Redis library found with `find_library`.

`recipe/patches/user-impl/conda-build.patch`: FairMQ >= 1.10 everywhere (upstream stops
at 1.10.0, and at 1.8 in LogicFilter and TriggerView), no `-march=native`, every
executable installed to `bin/`, and the internal static libraries (Utility, bundled
sqlite, AmQTdcModule) linked but not installed.

## Publication

Pushing a tag on `main` builds linux-64 and linux-aarch64 and uploads them:

- `2026.10.20`: the pinned snapshot. hep-bot pushes this tag on its next run, because
  the recipe has that version without a tag.
- `head`: upstream `main`. Move the tag to the tip of `main` to pick up recipe changes
  (`git tag -f head && git push -f origin refs/tags/head`); hep-bot does this when
  upstream moves.

Merging a PR or pushing to `main` publishes nothing.

```bash
conda install -c hep-forge -c conda-forge nestdaq              # pinned snapshot
conda install -c hep-forge -c conda-forge nestdaq=head         # upstream main
```

## Tests

The `CLI smoke tests` workflow builds the package on pull requests (AMD64, then ARM64)
and runs the recipe tests; it never uploads. The tests check the nestdaq plugins and web
assets, the user-impl executables and the uhbook headers, and run
`recipe/run_cli_smoke.py`: `--help` of Sampler, Sink and NullDevice, and the controller's
help and argument errors, without starting Redis or the web server. To run the CLI
checks against an installed package:

```bash
conda run -n nestdaq python recipe/run_cli_smoke.py
```
