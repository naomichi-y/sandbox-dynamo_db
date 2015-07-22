namespace :benchmark_records do
  desc 'create benchmark records'
  task :create => :environment do
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

    dynamo_db.batch_write_item({
      request_items: {
       DynamoDb::TABLE_BENCHMARK => [{
         put_request: {
           item: {
             id: 1,
             activity_date: '20150725',
             media: 'facebook'
           },
         }
       }]
      }
    })
  end
end
