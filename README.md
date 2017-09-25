# PartitionerPg

It's a gem for a partitioning Postgresql tables in Ruby on Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'partitioner_pg'
```

## Usage

1) Include PartitionerPg into your model - `include PartitionerPg`
Example:
```ruby
class YouModelName < ActiveRecord::Base
  include PartitionerPg

...
```
2) Create migration and add some instructions to it.
generate migration:
```
rails g migration make_partitioning_of_you_table
```
add instructions to migration:
```ruby
class YouMigrationClassName
  def change
    Article.create_partitioning_by_month_trigger_sql
    Article.create_month_table
    Article.create_next_month_table
  end
end

```
3) For correct work you need to create next_mont_table every month.
  I recommed to create rake task and run it once a day by crontab.
code for a rake task
```
Article.create_next_month_table
```
