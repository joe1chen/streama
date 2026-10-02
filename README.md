# Streama

[![CI RSpec Test](https://github.com/joe1chen/streama/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/joe1chen/streama/actions/workflows/test.yml)

A simple activity stream gem for **Mongoid**. You define activities (actor, verb, object, target) with the fields
to cache from each, and publishing an activity writes one `Activity` document per receiver, so reading a user's
stream is a single indexed query.

This is the [DOGOnews](https://www.dogonews.com)-maintained fork of
[christospappas/streama](https://github.com/christospappas/streama) (upstream is archived and read-only). It is
kept working on current Ruby, Rails, Mongoid and MongoDB versions.

**This fork uses fan-out-on-write**, unlike upstream's fan-out-on-read: upstream stores one activity document with
a `receivers` array, this fork stores one document per receiver with a single `receiver` hash (designed in 2011 so
the collection can be sharded by receiver). The two schemas are not compatible. Since 1.0.0 the `verb` is stored as
a `String` (BSON symbols are deprecated).

## Supported versions

Tested on every push by the [GitHub Actions matrix](https://github.com/joe1chen/streama/actions/workflows/test.yml)
([workflow](.github/workflows/test.yml)):

| Ruby | Rails | Mongoid | MongoDB |
|---|---|---|---|
| 2.7 | 6.1 | 7.5 | 6.0 |
| 3.0 | 6.1 | 8.0 | 6.0 |
| 3.1 | 7.0 | 8.1 | 7.0 |
| 3.2 | 7.1 | 8.1 | 7.0 |
| 3.2 | 7.2 | 9.0 | 7.0 |
| 3.3 | 7.2 | 9.0 | 8.0 |
| 3.4 | 8.0 | 9.0 | 8.0 |
| 2.7 | 6.1 | 7.5 (driver 2.26) | 8.0 |

The gemspec allows `mongoid >= 7.0, < 10` (and depends on `mongoid-compatibility`).

## Installation

This fork is not published to RubyGems (the `streama` gem there is upstream's); install it from GitHub, pinned to a
release tag ([releases](https://github.com/joe1chen/streama/releases)):

```ruby
# Gemfile
gem 'streama', github: 'joe1chen/streama', tag: 'v2.0.0'
```

Then `bundle install`.

## Usage

### Define activities

Create an `Activity` model and declare each activity with the fields to cache from the actor, object, target and
receiver:

```ruby
class Activity
  include Streama::Activity

  activity :new_photo do
    actor :user, cache: [:full_name]
    object :photo, cache: [:subject, :comment]
    target_object :album, cache: [:title]
  end

  # a namespaced class
  activity :new_mars_photo do
    actor :user, cache: [:full_name], class_name: 'Mars::User'
    object :photo
  end
end
```

The activity name is the verb (`"new_photo"`). The actor performs the activity, the object is what it was
performed on, and the target is where it happened — e.g. Geraldine (actor) posted a photo (object) to her album
(target). This follows the [Activity Streams 1.0](http://activitystrea.ms) vocabulary.

Each of `actor`, `object`, `target_object` and `receiver` is stored as a hash: `{"id" => ..., "type" => "ClassName"}`
plus the cached fields. Indexes are declared on `actor`, `object`, `target_object` (`id`, `type`) and on
`receiver.id`, `receiver.type`, `created_at`; create them once with `Activity.create_indexes`.

### Set up actors

```ruby
class User
  include Mongoid::Document
  include Streama::Actor

  field :full_name, type: String

  # default receivers when publish_activity is called without receivers:/receiver:
  def followers
    User.excludes(id: id)
  end
end
```

`activity_class SomeActivity` in the actor selects a model other than `::Activity`.

### Publish

```ruby
current_user.publish_activity(:new_photo, object: @photo, target_object: @album)                       # to #followers
current_user.publish_activity(:new_photo, object: @photo, target_object: @album, receivers: :friends)  # calls #friends
current_user.publish_activity(:new_photo, object: @photo, receivers: User.where(group_id: group.id))
current_user.publish_activity(:new_photo, object: @photo, receiver: current_user)                      # one receiver

# or without an actor helper
Activity.publish(:new_photo, { actor: user, object: photo, target_object: album, receivers: users })
```

Both return `nil`. With [mongo_followable](https://github.com/joe1chen/mongo_followable), `followers` returns
`Follow` records, not users, so pass `receivers: user.all_followers` explicitly.

`Activity.publish` takes a third options hash: `{ use_batch_insert: true, batch_size: 500 }` builds the
documents itself and writes them with `insert_many` in batches, skipping Mongoid callbacks and validations (it is
off by default).

### Read streams

```ruby
current_user.activity_stream                       # activities received, newest first
current_user.activity_stream(type: :new_photo)     # filtered by verb
current_user.actor_activity_stream                 # activities the user performed (and received)

activity.load_instance(:actor)                     # => the User (also :object, :target_object, :receiver)
activity.refresh_data                              # re-copy the cached fields and save
```

## Development

```bash
# needs a MongoDB on localhost:27017 (e.g. docker run -p 27017:27017 mongo:8.0)
MONGOID_VERSION=9.0 RAILS_VERSION=8.0 bundle install
MONGOID_VERSION=9.0 RAILS_VERSION=8.0 bundle exec rspec spec
```

`MONGOID_VERSION` and `RAILS_VERSION` select the versions in the `Gemfile` (defaults: Mongoid 7.5, Rails 6.1).
To add a combination to CI, add a row to `matrix.include` in `.github/workflows/test.yml`.

## Known issues

- `publish` / `publish_activity` return `nil`, not the created activities.
- Without `receivers:`/`receiver:`, receivers default to `actor.followers`, which must return actor-like
  documents (see the mongo_followable note above).
- `refresh_data` calls `save(validates_presence_of: false)`, which is not a real Mongoid option, so validations
  still run.
- `actor_activity_stream` filters on `receiver` *and* `actor.id`, so it only returns activities the actor also
  received (e.g. published with `receiver: self`).
- The `target` DSL method is deprecated in favour of `target_object`.

## History

Christos Pappas's original (2011) reached 0.3.8 on RubyGems (2014; upstream is now archived). DOGOnews forked it in
2011: 0.3.2.1–0.3.4.4 (2011–2014: one activity per receiver, batch insert, `actor_activity_stream`, upstream 0.3.4
merged in), 0.3.5 (2018: Mongoid 2–6 via mongoid-compatibility), 1.0.0 (2021: `verb` stored as a `String`), then
2.0.0 (2026: Mongoid 7.0–9.x on current Ruby/Rails/MongoDB, batch insert off by default).
See [CHANGELOG.md](CHANGELOG.md).

## Credits

- Christos Pappas ([@christospappas](https://github.com/christospappas)) — original author
- [Contributors](https://github.com/joe1chen/streama/graphs/contributors)

Copyright (c) 2011 Christos Pappas. Licensed under the MIT license, see [LICENSE.txt](LICENSE.txt).
