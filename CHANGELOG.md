# Changelog

All notable changes to NavBuddy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-09-08

### Added

- `__using__` macro for easy component import with `use NavBuddy.Component`
- Comprehensive validation with helpful error messages
- Convenience functions for creating navigation items:
  - `NavBuddy.nav_item/3` - Create simple navigation items
  - `NavBuddy.dropdown_item/3` - Create dropdown navigation items
  - `NavBuddy.mega_menu_item/3` - Create mega menu navigation items
- Improved type definitions with `required()` and `optional()` field specifications
- Support for simple mega menu format: `%{"Category" => [items]}`
- Better validation for conflicting navigation types (dropdown + mega_menu)
- Detailed field type validation with specific error messages

### Changed

- Enhanced error messages to include field requirements and suggestions
- Updated documentation with better examples and field explanations
- Improved validation to catch common mistakes early
- Made navigation logic validation more explicit

### Fixed

- Missing `__using__` macro that prevented `use NavBuddy.Component`
- Poor error messages that didn't explain what was wrong
- Undocumented navigation item structure requirements
- Complex mega menu requirements without simple alternatives

## [0.1.0] - 2025-09-08

### Added

- Initial release with core navigation functionality
- Phoenix LiveView components for responsive navigation
- Support for dropdown menus and mega menus
- Permissions-based navigation filtering
- Mobile-responsive design with drawer/overlay modes
- Comprehensive test suite
- Documentation and integration examples
