# Automatic Development Loop

## Overview

The automatic development loop is a systematic process for continuous improvement and development of the Flutter launcher application. Each loop ensures comprehensive code analysis, implementation, testing, and documentation.

## Loop Steps

### 1. Code Review and Analysis

Analyze the current codebase implementation:

- **Feature gaps**: Identify missing functionality or incomplete features
- **UI optimization**: Review user interface for improvements
- **Test coverage**: Identify areas lacking tests
- **Performance**: Find optimization opportunities
- **Refactoring**: Spot code that needs restructuring
- **Design improvements**: Review Material 3 compliance and UX

### 2. Task Prioritization

Select high-priority tasks and create implementation plan:

- Rank issues by impact and effort
- Consider dependencies between tasks
- Plan incremental implementation steps

### 3. Implementation

Implement the selected task:

- Follow Flutter best practices
- Reference relevant Flutter skills for guidance
- Maintain code consistency with existing patterns
- Use Material 3 components where applicable

### 4. Testing

Create corresponding tests:

- Write unit tests for logic
- Write widget tests for UI components
- Ensure edge cases are covered
- Test error handling paths

### 5. Test Execution and Fixes

Run all tests and fix any issues:

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && ~/app/flutter/bin/flutter test
```

- Fix any test failures
- Ensure all features work correctly
- Verify no regressions introduced

### 6. Application Launch

Start or reload the application:

```bash
~/app/flutter/bin/flutter run
```

- Resolve any startup errors
- Use hot reload for quick iterations
- Verify app runs on connected device/emulator

### 7. Debug Log Review

Check debug logs and resolve errors:

- Monitor console output
- Fix any runtime errors
- Address warnings appropriately
- Ensure smooth operation

### 8. Documentation

Create or update technical documentation in `docs/`:

- Document new features
- Update existing docs for changes
- Include code examples where helpful
- Follow existing documentation format

### 9. AGENTS.md Update

Update the AGENTS.md file:

- Add new architecture details
- Update known issues
- Document new providers or models
- Add new commands or configurations

### 10. Commit Changes

Create git commit with descriptive message:

```bash
git add .
git commit -m "type: description"
```

Use conventional commit types:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

### 11. Push to Remote

Push commits to remote repository:

```bash
git push
```

### 12. Next Loop

Read this file again and start a new loop:

Each loop must complete ALL steps in order for comprehensive development coverage.

## Quality Checklist

Before completing each loop, verify:

- [ ] Code compiles without errors
- [ ] All tests pass
- [ ] Application launches successfully
- [ ] No debug errors in console
- [ ] Documentation updated
- [ ] AGENTS.md updated
- [ ] Changes committed
- [ ] Changes pushed to remote

## Best Practices

- Complete each step fully before moving to next
- Document decisions and trade-offs
- Keep commits focused and atomic
- Run tests after each significant change
- Use hot reload during development for speed
- Monitor performance during testing