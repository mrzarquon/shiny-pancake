require 'puppet'
require 'json'
require 'pry'
require 'date'

$:.unshift(File.join(File.dirname(File.dirname(__FILE__))))

require 'puppet/reports/json_reporter'

RSpec.configure do |c|
  c.mock_with :rspec
end

def fixture_report(name)
  report_data = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'fixtures', "#{name}.json")))
  report_data['metrics'] = fixture_report_metrics(report_data.delete('metrics'))
  report_data['logs'] = fixture_report_logs(report_data.delete('logs'))
  report_data['resource_statuses'] = fixture_report_resource_statuses(report_data.delete('resource_statuses'))
  instance_double(Puppet::Transaction::Report, symbolise_keys(report_data))
end

def fixture_report_metrics(data)
  Hash[*(data.map { |category, category_data|
    [category, instance_double(Puppet::Util::Metric, symbolise_keys(category_data))]
  }).flatten(1)]
end

def fixture_report_logs(data)
  data.map do |log_entry|
    log_entry['time'] = DateTime.parse(log_entry['time'])
    instance_double(Puppet::Util::Log, symbolise_keys(log_entry))
  end
end

def fixture_report_resource_statuses(data)
  resource_statuses = data.map do |ref, resource_data|
    resource_data['events'] = fixture_report_events(resource_data.delete('events'))
    [ref, instance_double(Puppet::Resource::Status, symbolise_keys(resource_data))]
  end

  Hash[*resource_statuses.flatten(1)]
end

def fixture_report_events(data)
  data.map do |event|
    instance_double(Puppet::Transaction::Event, symbolise_keys(event))
  end
end

def symbolise_keys(hash)
  Hash[hash.map { |k, v| [k.to_sym, v] }]
end

describe 'thing' do
  it do
    report = fixture_report('notifies')
    s = JSONReporter::Schema.new('splunk_hec')
    expect(s.render_report(report)).to eq("")
  end
end
