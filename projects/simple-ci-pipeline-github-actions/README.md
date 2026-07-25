# Project: Simple CI pipeline with GitHub Actions

This project demonstrates a real, Docker-free Build → Test → Deploy CI pipeline for a small Python
package, run both locally and in GitHub Actions.

## Overview

### Introduction

- This project helps you understand and practice a staged CI pipeline (Build → Test → Deploy)
  where a build artifact is produced once and then promoted through the following stages.
- Tech stack: `Python`, `pytest`, `GitHub Actions`
- To get the basic concept of CI/CD, you could visit the
  [**devops-basic/ci-cd**](https://github.com/tungbq/devops-basics) repository

### Prerequisite

- `python3 >= 3.9` and `pip`
- A fork of this repository (to trigger the workflow on your own branch)
- **No Docker needed** — this project is intentionally Docker-free, unlike
  [nodejs-cicd-pipeline](../nodejs-cicd-pipeline/)

> If `python3 -m venv .venv` fails with `ensurepip is not available` (common on Debian/Ubuntu),
> install the matching package first: `sudo apt install python3.10-venv` (adjust the version
> suffix to your `python3 --version`).

## 1-Explore the app

```
src/simple_ci_app/
├── __init__.py     # exports add, subtract, multiply, divide
├── calculator.py   # 4 pure functions (divide raises ZeroDivisionError on y=0)
├── cli.py          # argparse CLI: simple-ci-app <op> <x> <y>
└── __main__.py     # enables `python -m simple_ci_app`
tests/
├── test_calculator.py
└── test_cli.py
```

`simple_ci_app` is intentionally trivial — the subject of this project is the pipeline, not the
app.

## 2-Run the pipeline locally

`./demo_project.sh` runs all three stages below in sequence. Or run them by hand:

### 2.1-Build

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
python -m build
```

Produces `dist/simple_ci_app-0.1.0-py3-none-any.whl` and `dist/simple_ci_app-0.1.0.tar.gz`.

### 2.2-Test

```bash
pip install dist/*.whl
pytest tests/ -v
```

Tests import the **installed wheel**, not `./src` — this proves the packaged artifact actually
works, not just the source tree.

### 2.3-Deploy (smoke)

```bash
simple-ci-app add 2 3
# 5.0
```

## 3-Run the pipeline in GitHub Actions

Workflow file:
[simple-ci-pipeline-github-actions.yml](https://github.com/tungbq/devops-project/blob/main/.github/workflows/simple-ci-pipeline-github-actions.yml)

### 3.1-Workflow triggers

Runs on `pull_request` / `push` to `main`, but only when files change under
`projects/simple-ci-pipeline-github-actions/**` or the workflow file itself (plus
`workflow_dispatch` for on-demand runs). This keeps unrelated PRs (e.g. editing another project's
files) from triggering this pipeline.

### 3.2-The three jobs

| Job      | Input                        | Command                               | Output                                |
| :------- | :---------------------------- | :------------------------------------- | :-------------------------------------- |
| `build`  | source checkout               | `python -m build`                      | `simple-ci-app-dist` artifact (wheel+sdist) |
| `test`   | `simple-ci-app-dist` artifact | `pip install dist/*.whl` + `pytest`    | pass/fail signal                        |
| `deploy` | `simple-ci-app-dist` artifact | install + smoke-run `simple-ci-app`    | `simple-ci-app-<sha>` artifact (7 days) |

Each job runs on a fresh runner; the built wheel is the only state carried between them (build
once, test that exact artifact, deploy that exact artifact).

### 3.3-Artifacts

Open the workflow run summary page → **Artifacts** section to download `simple-ci-app-dist` (the
build output) or `simple-ci-app-<sha>` (the deployed artifact, kept 7 days).

## 4-Make it deploy somewhere real

`deploy` here means "install the tested artifact and prove it runs, then publish it as a workflow
artifact" — no secrets, so it works on forked PRs too. To point it at a real target, swap the last
step of the `deploy` job for one of these:

**Gate deploy to `main` only:**

```yaml
- name: Publish deployable artifact
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  uses: actions/upload-artifact@v4
  ...
```

**Publish a GitHub Release** (needs `permissions: contents: write` on the `deploy` job only):

```yaml
permissions:
  contents: write
steps:
  - name: Upload release asset
    run: gh release upload ${{ github.ref_name }} dist/*.whl dist/*.tar.gz
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Publish to PyPI** (via trusted publishing / OIDC — never a raw API token in YAML):

```yaml
permissions:
  id-token: write
steps:
  - uses: pypa/gh-action-pypi-publish@release/v1
```

## 5-Bonus

- `./demo_project.sh` mirrors the CI stages exactly, so you can reproduce a red run locally before
  pushing.
- To test against multiple Python versions, turn `setup-python`'s `python-version` into a matrix:
  `strategy: matrix: python-version: ['3.9', '3.10', '3.12']` on the `build` job.

## Related link

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [actions/upload-artifact](https://github.com/actions/upload-artifact)
- [Python Packaging User Guide](https://packaging.python.org/en/latest/tutorials/packaging-projects/)
- [devops-basic/ci-cd](https://github.com/tungbq/devops-basics)
- Issue: [#5](https://github.com/tungbq/devops-project/issues/5)
