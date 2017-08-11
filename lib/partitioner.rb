require "partitioner/version"

module Partitioner
  extend ActiveSupport::Concern
  include SeparationType::Month

  #available types - :month
  def initialize(type)
    @type = type
  end

  module ClassMethods

    def partitioner(type)
      new(type.to_sym)
    end

    private

    def execute_sql(sql)
      connection.execute(sql)
    end

  end

end
