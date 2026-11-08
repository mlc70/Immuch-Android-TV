# Pull requests for this fork

- Before creating or editing a PR, read `.github/pull_request_template.md` and preserve every required `## ` heading exactly, including punctuation.
- Also fetch the current templates from the PR base branch and repository default branch. They can differ from this checkout. Preserve the union of their required headings and pass saved copies as additional arguments to the checker below.
- Fill in the description, actual validation results, applicable checklist items, and an honest AI-use disclosure. Leave unchecked items that have not been verified; mark irrelevant sections as not applicable.
- Write the complete PR body to a file, then run `node tools/check-pr-template.cjs <body-file>` before submitting it. Fix any missing headings before calling GitHub.
- This fork inherits an auto-close workflow that checks template headings on PR creation and edits. Do not disable that workflow to bypass a description failure.
- After creating a PR, ensure it has exactly one `changelog:*` label from `.github/release.yml`. Choose the category that matches the work (for example, `changelog:feature` for new functionality), preserve unrelated labels, and verify the label-validation result.
- Keep Android TV work on a separate branch. Do not merge into the default branch without the user's approval.

