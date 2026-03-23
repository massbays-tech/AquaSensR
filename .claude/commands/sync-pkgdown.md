# Sync _pkgdown.yml reference sections

Check that every exported function in the package is listed in `_pkgdown.yml`, and add any that are missing.

## Steps

1. Read `_pkgdown.yml` and collect every function name already listed under `reference:` (expanding any `starts_with()` / `ends_with()` / `contains()` helpers against the actual export list).

2. Get the full list of exported functions by running:
   ```r
   pkgload::load_all(quiet = TRUE)
   sort(getNamespaceExports('AquaSensR'))
   ```

3. Identify any exported functions **not** covered by the existing selectors or explicit entries.

4. For each uncovered function, suggest which existing section it belongs in based on its name prefix:
   - `read*`, `check*`, `form*` → "Read, check, and format data"
   - `utilASRflag*` or `anlzASRflag` → "Quality control"
   - `util*` (other) → "Utility functions"
   - `params*` or datasets → "Supplementary datasets"
   - Anything that doesn't fit → ask the user which section to put it in before making any changes.

5. If there are no uncovered functions, report that everything is already accounted for and stop.

6. Otherwise, show the user a summary of what will be added and where, confirm, then update `_pkgdown.yml` with the new entries. Add explicit function names (not new selectors) unless the user asks for a selector instead.

7. Run `devtools::document()` is NOT needed here — `_pkgdown.yml` changes don't require it.
