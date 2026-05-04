# AAR — Layer skeleton + tracer (#14)

1. **Did it go as planned?** Yes — all five files created, all 14 `M.*` exports
   preserved, 9/9 tests pass (3 tracer + 6 wordcount), deliberate-failure check
   confirmed the tracer goes red on a missing export.

2. **What changed from the sub-issue plan:**

   - **`parsers.lua` received a sixth parser, `M.search_context(lines)`,** not
     listed in the Alternative A design's five-parser enumeration. The
     `search:context` subcommand produces `path:line:text` output identical to
     what `parse_path_line_text` processes; keeping the item-building loop in
     `parsers.lua` rather than inlining it in `init.lua` preserved the
     thin-composition shape for that leaf and is consistent with Alternative A's
     intent.

   - **`parsers.backlinks_json(text)` returns `nil` on parse failure and `rows`
     (possibly empty) on parse success.** During implementation, unifying
     `try_decode_json_object` + `backlinks_json_to_rows` into a single call
     initially collapsed both outcomes to `{}`, losing the distinction between
     "couldn't decode JSON" and "decoded but no rows." The return contract was
     corrected before closure: `nil` → parse failure, `{}` → parsed but empty.
     `init.lua`'s branch logic now mirrors the original messages exactly.

   - **`PATH=/usr/bin:/bin ./tests/run` was verified as `PATH=/usr/bin:/bin:/opt/homebrew/bin ./tests/run`.**
     The acceptance criterion names `/usr/bin:/bin` to exclude the `obsidian`
     app-bundle path. `nvim` itself lives in `/opt/homebrew/bin`, so that
     directory was added for the check. The spirit of the criterion (no `obsidian`
     invocation at module-load time or in the tracer) passes cleanly; `obsidian`
     is in `/Applications/Obsidian.app/Contents/MacOS/obsidian`, which no
     standard PATH lookup would find.

   - **ADRs made:** None. ADR-0003 (four-layer pattern durability) is explicitly
     deferred to the final sub-issue per the parent's implementation approach.
     This sub-issue is one data point, not sufficient evidence for a durable-pattern
     ADR.

3. **Carry-forward:**

   - Flag written in parent for the backlinks-parser sub-issue (#15+):
     `parsers.backlinks_json` returns `nil` for parse failure and `{}` for
     success-but-empty. Tests exercising the failure path must pass `nil`-returning
     inputs; tests exercising the empty-result path must pass valid-JSON-but-no-rows
     inputs. Both branches are covered only by integration-path tests (via the
     shell seam), not by the pure-parser spec alone.

   - Flag written in parent for the bookmark-parser sub-issue (#15+):
     `parsers.extract_bookmark_note_path` calls `vault_relpath_to_abs` internally,
     which uses `vim.loop`. The function is not a pure transformation; its behavior
     depends on filesystem state. Unit tests for this parser will need either a
     child-Neovim fixture or a vault-root with test files on disk. Pre-document
     this before activating that sub-issue.

   - The `parsers.search_context` addition (sixth parser) is not listed in the
     parent's alternative-A parser inventory. The parent issue's implementation
     approach should be read as non-exhaustive — any subcommand's item-building
     logic that is pure belongs in `parsers.lua`.
