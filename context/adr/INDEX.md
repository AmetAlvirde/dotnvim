# ADR Index

| #    | Title                                          | Scope   | Status   | Summary                                                                              |
| ---- | ---------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------ |
| 0001 | mini.test as the test runner                   | product | accepted | Tests run via `mini.test` under `nvim --headless`.                                   |
| 0002 | Issue folder numbers track GitHub issue numbers | product | accepted | `issues/<NN>-name/` uses the GitHub issue number; cycle-local numbering has gaps.    |
| 0003 | Four-layer subpackage for shell-bound utilities  | product | accepted | Command builder / shell adapter / output parser / presenter in a submodule dir; only shell adapter invokes shell; setter seam on shell adapter (extended to parsers in #20). |
