# Changelog

All notable changes to Bamboo Mapper will be documented in this file.

## [2.0.0] - 2026-01-30

### Added
- Offline mode feature: Full offline functionality with local database sync
- UI redesign: Enhanced user interface with improved contrast and readability
- Improved modal loading behavior: Edit modal now displays only after data is loaded

### Changed
- Improved text contrast in view modal for better readability
- Optimized modal sizes for better user experience
- Enhanced label and input field color scheme

## [1.0.1] - 2026-01-12

### Added
- Auto-redirect to login page when session is invalid (refresh token expired)

### Fixed
- Fixed token refresh not working for multipart requests (create/update marker with image)
- Fixed FormData stream consumption issue during request retry after token refresh

## [1.0.0] - 2026-01-09

### Added
- Initial release of Bamboo Mapper
- Loading indicator
- Real time position
- Location picker with dragable marker & current position

### Changed

- Change map type
- Change integration to backend from supabase to direct REST API calls

### Fixed

- Fixed outdated versions
- Fixed build issues
