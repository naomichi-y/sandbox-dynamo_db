class DynamoDb
  TABLE_THREADS = 'test.threads'
  TABLE_BENCHMARK_THREADS = 'test.benchmark_threads'

  def connect
    Aws::DynamoDB::Client.new(
      # credentials: Aws::SharedCredentials.new(profile_name: 'private'),
      region: 'ap-northeast-1',
      endpoint: 'http://localhost:8000'
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
