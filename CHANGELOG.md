# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-01
DOGOnews fork. Major version because the minimum supported Mongoid rose from none (1.0.0) to 7.0, and
`Activity.publish` no longer batch-inserts by default.

### Added
- GitHub Actions test matrix (`.github/workflows/test.yml`), seven rows from Ruby 2.7 / Rails 6.1 /
  Mongoid 7.5 / MongoDB 6.0 to Ruby 3.4 / Rails 8.0 / Mongoid 9.0 / MongoDB 8.0. The `Gemfile` selects
  Rails and Mongoid from `RAILS_VERSION` / `MONGOID_VERSION` (defaults 6.1 / 7.5).
- GitHub Release workflow (`.github/workflows/release.yml`): pushing a `vX.Y.Z` tag creates a GitHub Release
  with this file's section as the notes.
- Spec for `publish` with `use_batch_insert: true`, checking it stores the same verb / actor / object /
  target_object / receiver shape as a regular publish.

### Changed
- `Activity.publish` defaults to `use_batch_insert: false`: each activity is saved through Mongoid (callbacks and
  validations run). Pass `use_batch_insert: true` for the previous `insert_many` path.
- Runtime dependency `mongoid >= 7.0, < 10` (was any version).
- Specs run on RSpec 3.13 (keeping the `should` syntax, enabled explicitly).
- The gemspec `homepage` points to this fork.
- README rewritten for the maintained fork (fan-out-on-write schema versus upstream, supported versions, usage
  checked against `lib/`, known issues); history moved to this file.

### Removed
- Travis CI configuration and the empty `README.rdoc`.

## [1.0.0] - 2021-09-14
### Changed
- `verb` is stored as a `String` instead of a `Symbol` (BSON symbols are deprecated).
- Tested on Rails 6 and Mongoid 7.0 / 7.1; specs use `database_cleaner-mongoid`.

## [0.3.5] - 2018-06-01
Not tagged here: the tag `v0.3.5` belongs to upstream's 0.3.5 (2012-06-27), a different commit that is not on
this branch. Upstream's 0.3.5–0.3.8 (tags `v0.3.5`–`v0.3.8`, released to RubyGems 2012–2014) were never merged
into this fork.
### Added
- Mongoid 3, 4, 5 and 6 support alongside Mongoid 2, using `mongoid-compatibility` (index declarations in the
  Mongoid 3+ syntax).
- Options for `Activity.publish(verb, data, options)`: `use_batch_insert` (default `true`) and `batch_size`
  (default 500); without batch insert every activity is saved through Mongoid.

### Changed
- Runtime dependencies `mongoid` (any version) and `mongoid-compatibility`.
- `actor`, `object`, `target_object` and `receiver` fields are untyped (were `Hash`).

## [0.3.4.4] - 2014-03-06
### Changed
- Development dependencies relaxed to `mongoid ~> 2` and `bson_ext ~> 1`.

### Fixed
- Batch insert with no receivers raised on Mongoid 2.8.

## [0.3.4.3] - 2013-02-19
### Fixed
- Batch insert of an activity with no cached fields.

## [0.3.4.2] - 2013-02-13
### Fixed
- Batch insert did not cache the activity's fields when the activity definition references the base class.

## [0.3.4.1] - 2012-04-04
### Changed
- Upstream 0.3.3 and 0.3.4 merged into the fork (`target` renamed `target_object`, optional caching).

### Removed
- The `Activity#publish` instance method (not supported by the one-document-per-receiver schema).

## [0.3.4] - 2012-02-12
### Changed
- Deprecation warning when an activity uses `target`; README examples use photos and albums.

## [0.3.3] - 2012-02-12
Upstream release; the fork's 0.3.2.x changes are not part of it.
### Changed
- The activity `target` field is renamed `target_object`; existing documents need a `$rename`.
- `mongoid ~> 2.4` is a development dependency only; jeweler replaced by `bundler/gem_tasks`.
- Caching of fields in the activity definition is optional.

### Removed
- The `InstanceMethods` module.

## [0.3.2.9] - 2012-01-17
### Changed
- All activities created by one `publish` call share the same `created_at`, which identifies them as one
  activity.

## [0.3.2.8] - 2011-11-29
### Fixed
- Indexes were not created on the right fields.

## [0.3.2.7] - 2011-11-29
### Added
- `actor_activity_stream`: the activities an actor has performed.
- `created_at` in the receiver index.

## [0.3.2.6] - 2011-07-13
### Fixed
- `created_at` was not saved by the batch insert.

## [0.3.2.5] - 2011-07-13
### Changed
- `publish` writes all activities with the MongoDB driver's batch insert, bypassing Mongoid.

## [0.3.2.4] - 2011-07-11
### Changed
- `publish` no longer returns the created activities (memory use).

## [0.3.2.3] - 2011-07-11
### Changed
- `publish` creates one activity per receiver for multiple receivers again.

### Removed
- `actor_stream_for` (include the actor in the receivers to see its own activities in its stream).

## [0.3.2.2] - 2011-07-08
### Added
- `:receiver` option to publish to a single receiver; `:receivers` (default `actor.followers`) restored.

## [0.3.2.1] - 2011-07-08
First DOGOnews version, with a storage schema that is incompatible with upstream.
### Changed
- One `Activity` document per receiver, with a single `receiver` hash instead of a `receivers` array, so the
  collection can be sharded by receiver (fan-out-on-write).

## [0.3.2] - 2011-06-29
### Removed
- The default `Actor#followers` method that raised `Streama::NoFollowersDefined`.

## [0.3.1] - 2011-06-29
### Changed
- Runtime dependency `mongoid ~> 2.0` (was `~> 2.0.0.rc`); `bson_ext` is no longer a runtime dependency.

## [0.3.0] - 2011-06-23
### Changed
- Activities follow the [Activity Streams](http://activitystrea.ms/) naming: the activity "target" is now called
  "object" and the "referrer" is now called "target" (not backwards compatible).

## [0.2.0] - 2011-05-31
### Changed
- Receivers are stored inside the activity document instead of a separate `Stream` collection; the activity
  definition was simplified.
- Activities without a target are allowed.

## [0.1.5] - 2011-03-29
### Added
- `Activity#refresh` to reassign the cached data.

### Changed
- `Activity#instance` renamed `Activity#load_instance`; destroying an activity destroys its streams.
- Runtime dependency `mongoid ~> 2.0.0.rc` (was `= 2.0.0.rc.7`).

## [0.1.4] - 2011-02-15
### Fixed
- `Actor#publish_activity` when activities are defined in an initializer instead of an `Activity` class.

## [0.1.3] - 2011-02-14
### Added
- `Activity#instance(type)` to load an activity's actor, target or referrer; indexes on the activity and stream
  collections.

## [0.1.2] - 2011-02-13
### Added
- `:receivers` option when publishing: an array of objects, or a symbol naming a method that returns them.

## [0.1.1] - 2011-02-11
### Changed
- Improved retrieval of activities.

## [0.1.0] - 2011-02-10
### Added
- Initial release by Christos Pappas: activity streams for Mongoid.

[Unreleased]: https://github.com/joe1chen/streama/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/joe1chen/streama/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/joe1chen/streama/compare/v0.3.4.4...v1.0.0
[0.3.4.4]: https://github.com/joe1chen/streama/compare/v0.3.4.3...v0.3.4.4
[0.3.4.3]: https://github.com/joe1chen/streama/compare/v0.3.4.2...v0.3.4.3
[0.3.4.2]: https://github.com/joe1chen/streama/compare/v0.3.4.1...v0.3.4.2
[0.3.4.1]: https://github.com/joe1chen/streama/compare/v0.3.4...v0.3.4.1
[0.3.4]: https://github.com/joe1chen/streama/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/joe1chen/streama/compare/v0.3.2.9...v0.3.3
[0.3.2.9]: https://github.com/joe1chen/streama/compare/v0.3.2.8...v0.3.2.9
[0.3.2.8]: https://github.com/joe1chen/streama/compare/v0.3.2.7...v0.3.2.8
[0.3.2.7]: https://github.com/joe1chen/streama/compare/v0.3.2.6...v0.3.2.7
[0.3.2.6]: https://github.com/joe1chen/streama/compare/v0.3.2.5...v0.3.2.6
[0.3.2.5]: https://github.com/joe1chen/streama/compare/v0.3.2.4...v0.3.2.5
[0.3.2.4]: https://github.com/joe1chen/streama/compare/v0.3.2.3...v0.3.2.4
[0.3.2.3]: https://github.com/joe1chen/streama/compare/v0.3.2.2...v0.3.2.3
[0.3.2.2]: https://github.com/joe1chen/streama/compare/v0.3.2.1...v0.3.2.2
[0.3.2.1]: https://github.com/joe1chen/streama/compare/v0.3.2...v0.3.2.1
[0.3.2]: https://github.com/joe1chen/streama/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/joe1chen/streama/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/joe1chen/streama/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/joe1chen/streama/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/joe1chen/streama/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/joe1chen/streama/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/joe1chen/streama/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/joe1chen/streama/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/joe1chen/streama/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/joe1chen/streama/releases/tag/v0.1.0
