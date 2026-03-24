require 'yaml'
require 'json'

REQUIRED_FIELDS = %w[name repo path ref description].freeze

top_dir = File.expand_path('..', __dir__)
yaml_files = Dir.glob(File.join(top_dir, '*.yaml')).sort

gems = yaml_files.map do |file|
  data = YAML.load_file(file)
  REQUIRED_FIELDS.each do |field|
    if data[field].nil? || data[field].to_s.strip.empty?
      raise "#{File.basename(file)}: missing required field '#{field}'"
    end
  end
  {
    'name'        => data['name'],
    'repo'        => data['repo'],
    'path'        => data['path'],
    'ref'         => data['ref'],
    'description' => data['description'],
    'tags'        => Array(data['tags'])
  }
end

gems.sort_by! { |g| g['name'] }

output_path = File.join(top_dir, 'artifact', 'index.json')
File.write(output_path, JSON.pretty_generate(gems))
puts "Wrote #{gems.size} gem(s) to #{output_path}"
