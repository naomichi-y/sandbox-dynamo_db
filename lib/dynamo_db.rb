class DynamoDb
  TABLE_TEST = 'sandbox-tests'
  TABLE_BENCHMARK = 'sandbox-benchmarks'

  def connect
    Aws::DynamoDB::Client.new(
      region: 'ap-northeast-1',
      # endpoint: 'http://localhost:8000'
    )
  end

  class Aws::DynamoDB::Client
    def exist_table?(table_name)
      begin
        describe_table({table_name: table_name}).table.table_status
        true
      rescue
        false
      end
    end
  end
end
