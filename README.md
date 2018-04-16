# PartitionerPg

It's a gem for a partitioning Postgresql tables in Ruby on Rails.
Now gem can help you with partitioning tables by months. New table for each month.

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
  
  # Point date or datetime column which will be used for monthly partitioning. Optional (:created_at uses by default)
  def self.parting_column
    :date
  end

  # List of indexes. Names of indexes will be generated by active migration. Optional.
  def self.partition_table_indexes
    [
      %w[column1 column2]
    ]
  end
  
  # Map of indexes. Full name of named index will be generated as "index_[partition_name]_[name_of_index_from_map]". Optional.
  def self.partition_table_named_indexes
    {
      :three_cols => %w[column1 column2 column3]
    }  
  end
  
  # List of unique indexes. Names of indexes wiil be generated by active migration. Optional.
  def self.partition_table_unique_indexes
    [
      %w[column1 column2 column3 column4]
    ]
  end
  
  # Map of named unique indexes. Optional.
  def self.partition_table_named_unique_indexes
    {
      :uniq => %w[column5 column6 column7]
    }
  end
end
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
    YouModel.create_partitioning_by_month_trigger_sql
    YouModel.create_month_table
    YouModel.create_next_month_table
  end
end

```
3) For correct work you need to create next_mont_table every month.
  I recommed to create rake task and run it once a day by crontab.
code for a rake task
```ruby
YouModel.create_next_month_table
```
