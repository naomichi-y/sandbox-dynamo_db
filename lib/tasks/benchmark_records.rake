namespace :benchmark_records do
  desc 'create benchmark records'
  task :drop => :environment do
    dynamo_db = DynamoDb.new.connect

    if dynamo_db.exist_table?(DynamoDb::TABLE_BENCHMARK)
      dynamo_db.delete_table({
        table_name: DynamoDb::TABLE_BENCHMARK,
      })
      dynamo_db.wait_until(:table_not_exists, {:table_name => DynamoDb::TABLE_BENCHMARK}) do |w|
        w.delay = 3
        w.max_attempts = 5
      end
    end
  end

  task :create => :environment do
    dynamo_db = DynamoDb.new.connect
    dynamo_db.create_table({
      attribute_definitions: [
        {
          attribute_name: 'id',
          attribute_type: 'N',
        },
        {
          attribute_name: 'activity_date',
          attribute_type: 'S',
        },
      ],
      table_name: DynamoDb::TABLE_BENCHMARK,
      key_schema: [
        {
          attribute_name: 'id',
          key_type: 'HASH',
        },
        {
          attribute_name: 'activity_date',
          key_type: 'RANGE'
        }
      ],
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1,
      }
    })
    dynamo_db.wait_until(:table_exists, {:table_name => DynamoDb::TABLE_BENCHMARK}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end
  end

  task :generate => :environment do
    items = []
    max_count = 10

    for i in 1..max_count do
      items << {
        # data size is 256byte
        put_request: {
          item: {
            id: i,
            activity_type: 'message_open',
            activity_date: '20150724',
            source: {
              type: 'facebook',
              code: 12345678
            },
            user_type: rand(1..8),
            previous_url: '/0123456789/0123456789/0123456789',
            access_date: 1436942578,
            session_id: '012345678901234567890123456789012'
          }
        }
      }
    end

    result = Benchmark.realtime do
      dynamo_db = DynamoDb.new.connect
      dynamo_db.batch_write_item({
        request_items: {
         DynamoDb::TABLE_BENCHMARK => items
        }
      })
    end

    puts "#{max_count} record registered. [#{result}sec]"
  end
end
