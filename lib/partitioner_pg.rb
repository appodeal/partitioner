require "partitioner_pg/version"
require "partitioner_pg/separation_type/month"

module PartitionerPg
  extend ActiveSupport::Concern

  #available types - :month
  def initialize(type)
    @type = type
  end

  module ClassMethods
    include SeparationType::Month

    def partitioner_pg(type)
      new(type.to_sym)
      puts TEST0
    end

    private

    def execute_sql(sql)
      connection.execute(sql)
    end

  end

end
