namespace :benchmark_records do
  desc 'create benchmark table/records'
  task :setup => :environment do
    Rake::Task['benchmark_records:drop'].invoke
    Rake::Task['benchmark_records:create'].invoke
    Rake::Task['benchmark_records:generate'].invoke
  end

  desc 'drop benchmark table'
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

    puts 'Drop table.'
  end

  desc 'create benchmark table'
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
        read_capacity_units: 20,
        write_capacity_units: 20,
      }
    })
    dynamo_db.wait_until(:table_exists, {:table_name => DynamoDb::TABLE_BENCHMARK}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end

    puts 'Created table.'
  end

  desc 'create benchmark records'
  task :generate => :environment do
    dynamo_db = DynamoDb.new.connect

    id = 1
    batch_limit = 25
    created_count = 0
    max_count = 7000
    activity_date = Time.now.strftime("%Y%m%d")

    execute_time = Benchmark.realtime do
      while max_count > created_count
        items = []

        if max_count - created_count < batch_limit
          batch_limit = max_count - created_count
        end

        batch_limit.times do
          items << {
            put_request: {
              item: {
                id: id,
                activity_type: 'message_open',
                activity_date: activity_date,
                source: {
                  type: 'facebook',
                  code: 12345678
                },
                user_type: rand(1..8),
                previous_url: '/0123456789/0123456789/0123456789',
                access_date: Time.now.to_i,
                session_id: [*1..9, *'A'..'Z', *'a'..'z'].sample(32).join
              }
            }
          }

          id += 1
        end

        # If an exception does not occur
        response = dynamo_db.batch_write_item({
          request_items: {
           DynamoDb::TABLE_BENCHMARK => items
          }
        })

        if response.unprocessed_items.count > 0
          p "Write failure! (retry wait #{wait}sec)"
          wait = 3

          begin
            sleep(wait)
            response = dynamo_db.batch_write_item({
              request_items: {
               DynamoDb::TABLE_BENCHMARK => items
              }
            })

            wait * 2
          end while response.unprocessed_items.count > 0
        end

        created_count += batch_limit
        puts "generate #{created_count} records"
      end
    end

    puts "#{max_count} record registered. [#{execute_time}sec]"
  end
end
