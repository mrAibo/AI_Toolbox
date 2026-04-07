# Task: CI Enhancements and Workflow Automation

- Status: ready
- Priority: high
- Owner: AI agent
- Related files: .github/workflows/ci.yml, .agent/scripts/
- Goal: Expand CI validation, add more workflow automations, improve developer experience
- Steps:
    - [ ] Add bootstrap parity check to CI (compare .sh vs .ps1 outputs)
    - [ ] Add trailing newline validation to CI
    - [ ] Add JSON schema validation for client-capabilities.json
    - [ ] Consider adding automated test suite for shell/PowerShell scripts
    - [ ] Document setup process in INSTALL.md
- Verification: CI passes, all checks green, bootstrap flow works end-to-end
- Notes: Review all 5 rounds completed, all issues resolved. Ready for next phase.
