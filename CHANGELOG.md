# Changelog

All notable changes to NavBuddy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2025-09-08

### Fixed

- **CRITICAL**: Fixed all potential KeyError issues throughout the component system
- Replaced direct field access (`@item.field`) with safe access (`Map.get(@item, :field)`) for all optional fields:
  - `navigate`, `active`, `disabled`, `icon`, `dropdown`, `mega_menu`, `permissions`
- Fixed KeyErrors in conditional rendering (`:if` attributes)
- Fixed KeyErrors in class generation and data attributes
- Fixed KeyErrors in event handlers and navigation logic

### Added

- Comprehensive tests for minimal navigation items (only required fields)
- Tests for partial navigation items (some but not all optional fields)
- Tests ensuring permission filtering works safely with minimal items

### Changed

- All optional field access now uses `Map.get/2` for guaranteed safety
- Component rendering is now completely safe with any valid navigation item structure

## [0.2.2] - 2025-09-08

### Fixed

- **CRITICAL**: Fixed KeyError when `description` key is missing from mega menu or mega menu sections
- Used `Map.get/2` for safe access to optional `description` fields in mega menu templates
- Added comprehensive tests for both simple and structured mega menu formats

### Added

- Tests for mega menu validation covering both simple and structured formats
- Tests for optional description fields in mega menus

## [0.2.1] - 2025-09-08

### Fixed

- **CRITICAL**: Fixed mega menu component causing KeyError when using simple mega menu format `%{"Category" => [items]}`
- Added proper handling for both simple and structured mega menu formats in the component template
- Added documentation clarifying the two supported mega menu formats

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
