# Version Management Guide

## Semantic Versioning

Format: `MAJOR.MINOR.PATCH` (e.g., 1.2.3)

- **MAJOR**: Breaking changes (1.0.0 → 2.0.0)
- **MINOR**: New features, backward compatible (1.0.0 → 1.1.0)
- **PATCH**: Bug fixes (1.0.0 → 1.0.1)

## Quick Commands

### Bump Version

```bash
cd Web

# Bug fix (1.0.0 → 1.0.1)
npm run version:patch

# New feature (1.0.0 → 1.1.0)
npm run version:minor

# Breaking change (1.0.0 → 2.0.0)
npm run version:major
```

These commands automatically:
1. Update version in `package.json`
2. Create a git commit
3. Create a git tag (e.g., `v1.0.1`)

### Manual Version Update

```bash
# Edit package.json manually
"version": "1.2.3"

# Then commit and tag
git add package.json
git commit -m "Bump version to 1.2.3"
git tag v1.2.3
git push origin main --tags
```

## Deployment Workflow

### 1. Make Changes
```bash
# Work on features
git add .
git commit -m "Add new feature"
```

### 2. Bump Version
```bash
cd Web
npm run version:minor  # Creates v1.1.0 tag
```

### 3. Push to GitHub
```bash
git push origin main --tags
```

### 4. Vercel Auto-Deploys
- Vercel detects the push
- Builds and deploys automatically
- New version goes live

## Version Display

The app now shows version in the footer:
- Reads from `package.json`
- Displays as "Stash v1.0.0"
- Visible to users

## Release Notes (Optional)

Create `CHANGELOG.md` to track changes:

```markdown
# Changelog

## [1.1.0] - 2026-02-06
### Added
- Export to CSV/HTML
- Grid view mode
- Version display in footer

### Fixed
- Search performance improvements

## [1.0.0] - 2026-01-11
### Added
- Initial release
- CloudKit sync
- Demo mode
```

## Git Tags

View all versions:
```bash
git tag
# v1.0.0
# v1.0.1
# v1.1.0
```

Checkout specific version:
```bash
git checkout v1.0.0
```

Delete tag:
```bash
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

## Vercel Environment Variables (Optional)

Set version as environment variable:
```bash
# In Vercel dashboard
REACT_APP_VERSION=1.0.0
```

Then in code:
```javascript
const APP_VERSION = process.env.REACT_APP_VERSION || require('../package.json').version;
```

## Best Practices

1. **Always bump version before release**
2. **Use tags for releases** - Easy rollback
3. **Keep CHANGELOG.md updated** - Track what changed
4. **Test before bumping** - Don't version broken code
5. **Push tags to GitHub** - `git push --tags`

## Current Setup

✅ Version in `package.json`: 1.0.0
✅ Version scripts added
✅ Version displayed in app footer
✅ Ready for git tagging

## Next Steps

1. Make your first release:
   ```bash
   cd Web
   npm run version:patch  # Creates v1.0.1
   git push origin main --tags
   ```

2. Vercel will auto-deploy the new version

3. Users will see "Stash v1.0.1" in the footer
