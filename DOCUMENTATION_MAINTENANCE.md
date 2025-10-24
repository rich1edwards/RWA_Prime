# Documentation Maintenance Guide

## Purpose

This guide ensures RWA Prime's documentation stays accurate, current, and useful as the codebase evolves. **Documentation is code** - it should be updated with the same rigor as source code.

---

## 📅 When to Update Documentation

### After Every Major Change

| Change Type | Documentation to Update | Why |
|-------------|------------------------|-----|
| **Code Structure Changes** | CODEBASE_MAP.md | Keep file/directory references accurate |
| **New Features** | ARCHITECTURE.md + API_REFERENCE.md | Document new components and endpoints |
| **New Dependencies** | DEPENDENCIES.md | Track external services and libraries |
| **Process Changes** | DEVELOPMENT_GUIDE.md | Keep setup/workflow instructions current |
| **Completed Tasks** | TASKS_AND_TODO.md | Reflect current priorities and progress |
| **Architecture Changes** | ARCHITECTURE.md + 00_START_HERE.md | Update diagrams and component descriptions |
| **API Changes** | API_REFERENCE.md | Keep endpoint documentation in sync |
| **Security Updates** | CLAUDE_INSTRUCTIONS.md | Update security guidelines |
| **Testing Strategy** | TESTING_GUIDE.md | Document new testing approaches |

### Specific Triggers

#### When Adding a New File/Directory
**Update**: CODEBASE_MAP.md
```markdown
Add entry:
- File path
- Purpose
- Key functions/exports
- Related files
```

#### When Adding/Removing Dependencies
**Update**: DEPENDENCIES.md
```markdown
Add:
- Package name + version
- Purpose
- Cost (if applicable)
- Known issues/constraints
```

#### When Creating a New API Endpoint
**Update**: API_REFERENCE.md
```markdown
Add:
- Endpoint path
- HTTP method
- Request/response formats
- Authentication requirements
- Error codes
- Example usage
```

#### When Modifying Database Schema
**Update**: ARCHITECTURE.md
```markdown
Update:
- Database Schema section
- ERD diagram (if applicable)
- Migration notes
```

#### When Changing Development Workflow
**Update**: DEVELOPMENT_GUIDE.md
```markdown
Update:
- Setup instructions
- Build/deploy processes
- Git workflow
- Common tasks
```

#### When Completing/Adding Tasks
**Update**: TASKS_AND_TODO.md
```markdown
- Mark completed tasks with [x]
- Add new tasks discovered
- Update priorities
- Adjust timelines
```

---

## ✅ Documentation Review Checklist

Use this checklist when reviewing documentation for accuracy:

### General Checks
- [ ] Are all file paths still accurate?
- [ ] Do all code examples compile/run?
- [ ] Are version numbers current (Python, Node, packages)?
- [ ] Are setup instructions still valid?
- [ ] Are screenshots/diagrams up to date?
- [ ] Are external links still working?
- [ ] Is terminology consistent across docs?

### Specific Document Checks

#### PROJECT_CONTEXT.md
- [ ] Project goals still accurate?
- [ ] Target market description current?
- [ ] Technology stack list up to date?
- [ ] Success metrics still relevant?
- [ ] Current phase/status accurate?

#### ARCHITECTURE.md
- [ ] System diagram reflects current architecture?
- [ ] Component descriptions accurate?
- [ ] Data flow diagrams current?
- [ ] Database schema matches actual schema?
- [ ] Technology versions correct?

#### DEVELOPMENT_GUIDE.md
- [ ] Setup instructions work on fresh machine?
- [ ] Docker commands execute successfully?
- [ ] Environment variables list complete?
- [ ] Build/deploy processes accurate?
- [ ] Troubleshooting tips still relevant?

#### CODEBASE_MAP.md
- [ ] All listed files/directories exist?
- [ ] File purposes accurately described?
- [ ] Key functions still present?
- [ ] Entry points correct?
- [ ] Import paths accurate?

#### API_REFERENCE.md
- [ ] All endpoints documented?
- [ ] Request/response formats match code?
- [ ] Authentication flow accurate?
- [ ] Error codes complete?
- [ ] Examples work with current API?

#### DEPENDENCIES.md
- [ ] All dependencies listed?
- [ ] Versions match package.json/requirements.txt?
- [ ] Cost estimates current?
- [ ] API key requirements accurate?

#### TESTING_GUIDE.md
- [ ] Test commands execute successfully?
- [ ] Coverage requirements current?
- [ ] Test examples run and pass?
- [ ] CI/CD integration accurate?

#### TASKS_AND_TODO.md
- [ ] Completed tasks marked as done?
- [ ] Current tasks reflect actual priorities?
- [ ] Timeline estimates realistic?
- [ ] Dependencies between tasks noted?

---

## 🤖 Automated Documentation Reminders

### Git Hooks

Create `.git/hooks/pre-commit` to remind about documentation:

```bash
#!/bin/bash

# Check for documentation updates needed

echo "Checking for documentation update requirements..."

# Check if package.json changed
if git diff --cached --name-only | grep -q "package.json"; then
    echo "⚠️  package.json changed - Consider updating DEPENDENCIES.md"
fi

# Check if requirements.txt changed
if git diff --cached --name-only | grep -q "requirements.txt"; then
    echo "⚠️  requirements.txt changed - Consider updating DEPENDENCIES.md"
fi

# Check if new directories created
NEW_DIRS=$(git diff --cached --name-only --diff-filter=A | xargs -I {} dirname {} | sort -u)
if [ ! -z "$NEW_DIRS" ]; then
    echo "⚠️  New directories detected - Consider updating CODEBASE_MAP.md"
    echo "$NEW_DIRS"
fi

# Check if API routes changed
if git diff --cached --name-only | grep -q "routes/"; then
    echo "⚠️  API routes changed - Consider updating API_REFERENCE.md"
fi

# Check if database models changed
if git diff --cached --name-only | grep -q "models.py\|schema"; then
    echo "⚠️  Database models changed - Consider updating ARCHITECTURE.md"
fi

echo ""
echo "✅ If any warnings above, please update relevant documentation."
echo ""
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### GitHub Actions CI Check

Create `.github/workflows/doc-check.yml`:

```yaml
name: Documentation Check

on:
  pull_request:
    branches: [ main, develop ]

jobs:
  doc-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check for doc updates
        run: |
          echo "Checking if documentation needs updates..."

          # Check if code changed but docs didn't
          CODE_CHANGED=$(git diff --name-only origin/main...HEAD | grep -E '\.(py|ts|tsx|js)$' | wc -l)
          DOCS_CHANGED=$(git diff --name-only origin/main...HEAD | grep '\.md$' | wc -l)

          if [ $CODE_CHANGED -gt 10 ] && [ $DOCS_CHANGED -eq 0 ]; then
            echo "⚠️  Warning: Significant code changes without doc updates"
            echo "Consider updating relevant documentation files"
          fi

          # Check specific files
          if git diff --name-only origin/main...HEAD | grep -q "package.json"; then
            if ! git diff --name-only origin/main...HEAD | grep -q "DEPENDENCIES.md"; then
              echo "⚠️  package.json changed but DEPENDENCIES.md not updated"
            fi
          fi

          if git diff --name-only origin/main...HEAD | grep -q "requirements.txt"; then
            if ! git diff --name-only origin/main...HEAD | grep -q "DEPENDENCIES.md"; then
              echo "⚠️  requirements.txt changed but DEPENDENCIES.md not updated"
            fi
          fi

      - name: Check doc links
        run: |
          echo "Checking for broken internal links..."
          # Add link checker here
```

### VS Code Extension Recommendations

Add to `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "yzhang.markdown-all-in-one",
    "DavidAnson.vscode-markdownlint",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

---

## 📝 Documentation Update Workflow

### For Developers

1. **Before Starting Work**:
   - Read relevant documentation
   - Note what may need updating

2. **During Development**:
   - Keep a list of doc changes needed
   - Update inline code comments

3. **Before Committing**:
   - Update affected documentation files
   - Run documentation checklist
   - Ensure examples still work

4. **In Pull Request**:
   - List documentation changes in PR description
   - Tag docs for review

### For AI Assistants (Claude)

When making code changes, automatically update:

```python
# Example: After adding new API endpoint
# 1. Implement the code
# 2. Write tests
# 3. Update API_REFERENCE.md with:
#    - Endpoint path
#    - Request/response format
#    - Example usage
# 4. Update CODEBASE_MAP.md if new file created
```

---

## 🔄 Documentation Review Schedule

### Weekly (Every Friday)
- [ ] Quick scan of TASKS_AND_TODO.md
- [ ] Update completed tasks
- [ ] Adjust current priorities

### Monthly (First Monday)
- [ ] Review all documentation for accuracy
- [ ] Update version numbers
- [ ] Check external links
- [ ] Review and update cost estimates in DEPENDENCIES.md

### Quarterly (Start of Quarter)
- [ ] Major documentation audit
- [ ] Reorganize if needed
- [ ] Update architecture diagrams
- [ ] Review and update all examples
- [ ] Update learning paths and onboarding guides

### Before Major Releases
- [ ] Complete documentation review checklist
- [ ] Ensure all API changes documented
- [ ] Update CHANGELOG.md (if exists)
- [ ] Review CLAUDE_INSTRUCTIONS.md for any new patterns

---

## 🎯 Documentation Quality Standards

### Writing Style
- **Clear and Concise**: Use simple language
- **Consistent**: Use same terminology across all docs
- **Actionable**: Provide specific steps, not vague descriptions
- **Examples**: Include code examples where applicable
- **Updated Dates**: Note when documentation was last updated

### Formatting Standards
- Use proper markdown headers (# for h1, ## for h2, etc.)
- Include table of contents for documents >500 lines
- Use code blocks with language tags (```python, ```typescript)
- Use tables for structured information
- Use emoji sparingly and consistently (✅ ❌ ⚠️ 📝 🔍)

### Code Examples
- Must compile/run successfully
- Include imports and context
- Show both request and response
- Include error handling
- Add comments explaining complex parts

---

## 🚨 Common Documentation Pitfalls

### ❌ Don't:
- Copy-paste code without testing it
- Use outdated screenshots/diagrams
- Leave TODO comments in documentation
- Create documentation that duplicates code comments
- Forget to update related documents

### ✅ Do:
- Test all commands and examples
- Keep diagrams as code (e.g., Mermaid)
- Link between related documents
- Use relative paths for internal links
- Version control documentation with code

---

## 📊 Documentation Metrics

Track these metrics to ensure documentation health:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Freshness** | < 30 days since last update | Git commit dates |
| **Accuracy** | 100% working examples | Manual testing |
| **Completeness** | All features documented | Feature checklist |
| **Link Health** | 0 broken links | Link checker tool |
| **Readability** | Flesch score > 60 | Readability tool |

---

## 🛠️ Tools for Documentation

### Recommended Tools
- **Markdown Editors**: VS Code, Typora, Mark Text
- **Diagram Tools**: Mermaid, Draw.io, Excalidraw
- **Link Checkers**: markdown-link-check, linkchecker
- **Spell Checkers**: aspell, cSpell (VS Code)
- **API Doc Generators**: Swagger/OpenAPI for API_REFERENCE.md

### Automation Tools
- **Pre-commit hooks**: Check for doc updates
- **GitHub Actions**: Automated link checking
- **Dependabot**: Dependency version updates
- **Changelog generators**: conventional-changelog

---

## 📞 Getting Help with Documentation

### Questions About What to Document
- Review similar sections in existing docs
- Ask: "Would a new developer need to know this?"
- Consult CLAUDE_INSTRUCTIONS.md for guidance

### Questions About How to Document
- Follow existing formatting in the same file
- Check DEVELOPMENT_GUIDE.md for writing style
- Look at code examples in TESTING_GUIDE.md

### Technical Writing Resources
- [Google Developer Documentation Style Guide](https://developers.google.com/style)
- [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/)
- [Write the Docs](https://www.writethedocs.org/)

---

## 🎓 Documentation Onboarding

For new team members responsible for docs:

**Week 1**: Read all documentation
**Week 2**: Update one small doc (fix typos, update links)
**Week 3**: Update one major doc (add new feature documentation)
**Week 4**: Own a documentation review cycle

---

## 📋 Documentation Update Template

When updating docs, use this commit message format:

```
docs: update [FILE] - [WHAT CHANGED]

- Changed: [specific changes]
- Added: [new sections]
- Removed: [deprecated info]
- Fixed: [corrections]

Related to: [ISSUE/PR #]
```

Example:
```
docs: update API_REFERENCE.md - add portfolio sync endpoint

- Added: POST /portfolio/sync-wallet endpoint
- Updated: Authentication section with new tier requirements
- Fixed: Typo in error response format

Related to: #123
```

---

**Last Updated**: October 23, 2025
**Version**: 1.0
**Owner**: Development Team

---

**Remember**: Good documentation is a gift to your future self and your teammates. Keep it current! 🎁
