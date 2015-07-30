class BenchmarksController < ApplicationController
  def query
    @execute_time = Benchmark.realtime do
      @response = @dynamo_db.query({
        table_name: DynamoDb::TABLE_BENCHMARK,
        index_name: 'index_thread_group_id',

        ## Use hash
        key_condition_expression: 'thread_group_id = :thread_group_id',
        expression_attribute_values: {
          ':thread_group_id' => 1,
          ':subject' => '3'
        },

        filter_expression: 'contains(subject, :subject)',
      })
    end
  end
end
