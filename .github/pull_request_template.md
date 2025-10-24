# Pull Request

## Description

<!-- Provide a brief description of the changes in this PR -->

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test coverage improvement
- [ ] Infrastructure/DevOps change

## Related Issues

<!-- Link to related issues using #issue_number -->

Closes #
Related to #

## Changes Made

<!-- Provide a detailed list of changes -->

-
-
-

## Documentation Updates

<!-- Check all that apply and provide details -->

- [ ] **ARCHITECTURE.md** - Updated system architecture/component descriptions
- [ ] **API_REFERENCE.md** - Added/updated API endpoint documentation
- [ ] **CODEBASE_MAP.md** - Updated file structure/module descriptions
- [ ] **DEPENDENCIES.md** - Added/updated dependencies
- [ ] **DEVELOPMENT_GUIDE.md** - Updated setup/workflow instructions
- [ ] **TESTING_GUIDE.md** - Updated testing strategy/examples
- [ ] **TASKS_AND_TODO.md** - Updated task status/priorities
- [ ] **DIAGRAMS.md** - Updated Mermaid diagrams
- [ ] **README.md** - Updated project overview
- [ ] **Other** - Specify: _______________
- [ ] **No documentation changes needed** - Explain why: _______________

## Testing

<!-- Describe the testing you've done -->

### Test Coverage

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] E2E tests added/updated
- [ ] All existing tests pass
- [ ] Coverage meets minimum threshold (80%)

### Manual Testing

<!-- Describe manual testing performed -->

-
-

### Test Commands Run

```bash
# Example:
# pytest tests/unit/test_new_feature.py
# npm run test:integration
```

## Code Quality Checklist

<!-- Verify code quality standards -->

- [ ] Code follows project style guidelines (PEP 8 for Python, Airbnb for TypeScript)
- [ ] Code has been formatted (Black for Python, Prettier for TypeScript)
- [ ] Code has been linted (pylint/flake8 for Python, ESLint for TypeScript)
- [ ] No unnecessary console.log() or print() statements
- [ ] Sensitive data properly handled (no hardcoded secrets)
- [ ] Error handling implemented appropriately
- [ ] Code is DRY (Don't Repeat Yourself)
- [ ] Functions/methods have clear, single responsibilities

## Security Considerations

<!-- Address any security implications -->

- [ ] No sensitive data exposed in logs or responses
- [ ] Input validation implemented
- [ ] SQL injection protection verified (if applicable)
- [ ] XSS protection verified (if applicable)
- [ ] Authentication/authorization properly implemented (if applicable)
- [ ] Secrets managed via environment variables
- [ ] CORS configured correctly (if applicable)

## Database Changes

<!-- If database changes are included -->

- [ ] Migration scripts created
- [ ] Migration tested on dev environment
- [ ] Migration is reversible (has down migration)
- [ ] ARCHITECTURE.md updated with schema changes
- [ ] Data seeding scripts updated (if needed)

## API Changes

<!-- If API changes are included -->

- [ ] Breaking changes clearly documented
- [ ] Backward compatibility maintained OR migration path provided
- [ ] API_REFERENCE.md updated with new/changed endpoints
- [ ] Request/response examples provided
- [ ] Error responses documented
- [ ] Authentication requirements documented

## Performance Impact

<!-- Describe any performance implications -->

- [ ] No significant performance degradation
- [ ] Performance tested under load (if applicable)
- [ ] Database queries optimized (if applicable)
- [ ] Caching strategy implemented (if applicable)
- [ ] Performance metrics: _______________

## Deployment Notes

<!-- Special instructions for deployment -->

### Environment Variables

<!-- List any new environment variables -->

```bash
# Example:
# NEW_API_KEY=xxx
# FEATURE_FLAG_XYZ=true
```

### Migration Steps

<!-- List any manual steps required for deployment -->

1.
2.
3.

### Rollback Plan

<!-- Describe how to rollback if issues arise -->



## Screenshots/Videos

<!-- Add screenshots or videos demonstrating the changes (if applicable) -->



## Reviewer Notes

<!-- Any specific areas you'd like reviewers to focus on -->

-
-

## Checklist Before Requesting Review

- [ ] Code is self-reviewed
- [ ] Code has been tested locally
- [ ] All tests pass
- [ ] Documentation has been updated
- [ ] Commit messages follow conventional commits format
- [ ] Branch is up to date with base branch
- [ ] No merge conflicts
- [ ] CI/CD pipeline passes

---

**For Reviewers:**

Please verify:
- [ ] Code quality and style compliance
- [ ] Test coverage is adequate
- [ ] Documentation is complete and accurate
- [ ] Security considerations addressed
- [ ] Performance impact is acceptable
- [ ] Changes align with project architecture
