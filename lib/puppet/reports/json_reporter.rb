require 'yaml'
require 'json'

module JSONReporter
  class Schema
    attr_reader :schema_name
    attr_reader :schema
    attr_reader :batch_method

    def initialize(schema_name)
      @schema_name = schema_name
      load_schema_file
    end

    def schema_dir
      File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'schemas'))
    end

    def load_schema_file
      schema_file = File.join(schema_dir, "#{schema_name}.yaml")
      return unless File.file?(schema_file)
      data = YAML.safe_load(File.read(schema_file), :symbolize_names => true)

      @schema = data[:schema]
      @batch_method = data[:batch_method] || :none
    end

    def render_report(report)
      events = []

      report_data = {
        :host                  => report.host,
        :configuration_version => report.configuration_version,
        :catalog_uuid          => report.catalog_uuid,
        :status                => report.status,
        :noop                  => report.noop,
        :noop_pending          => report.noop_pending,
        :environment           => report.environment,
        :corrective_change     => report.corrective_change,
      }

      report.logs.each do |log_event|
        template_data = report_data.merge(
          :log_event_file    => log_event.file,
          :log_event_line    => log_event.line,
          :log_event_level   => log_event.level,
          :log_event_message => log_event.message,
          :log_event_source  => log_event.source,
          :log_event_tags    => log_event.tags,
          :log_event_time    => log_event.time.to_s,
          :log_event_epoch   => log_event.time.to_time.to_i,
        )

        events << render_event_hash(@schema, template_data)
      end

      if batch_method.to_sym == :concatenate
        events.map(&:to_json).join('')
      else
        events
      end
    end

    def render_event_hash(hash, data)
      rendered_hash = {}

      hash.each do |key, value|
        if value.is_a?(Hash)
          rendered_hash[key] = render_event_hash(value, data)
        else
          rendered_hash[key] = value % data
        end
      end

      rendered_hash
    end
  end
end
