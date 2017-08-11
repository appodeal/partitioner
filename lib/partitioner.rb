require "partitioner/version"

module Partitioner
  extend ActiveSupport::Concern

  module ClassMethods
    include SeparationType::Month

    private

    def execute_sql(sql)
      connection.execute(sql)
    end

  end

end
