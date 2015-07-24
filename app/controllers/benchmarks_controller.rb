class BenchmarksController < ApplicationController
  def query
    @execute_time = Benchmark.realtime do
      @response = @dynamo_db.query({
        table_name: DynamoDb::TABLE_BENCHMARK,
        index_name: 'index_user_type',

        ## Use hash
        key_condition_expression: 'user_type = :user_type',
        expression_attribute_values: {
          ':user_type' => 1,
          ':activity_type' => 1
        },

        filter_expression: 'activity_type = :activity_type',
      })
    end
  end
end
