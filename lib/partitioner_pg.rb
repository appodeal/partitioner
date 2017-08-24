require "partitioner_pg/version"
require "partitioner_pg/separation_type/month"

module PartitionerPg
  extend ActiveSupport::Concern
  include SeparationType::Month

  #available types - :month
  def initialize(type)
    @type = type
  end

  module ClassMethods

    def partitioner_pg(type)
      new(type.to_sym)
    end

    private

    def execute_sql(sql)
      connection.execute(sql)
    end

  end

end
