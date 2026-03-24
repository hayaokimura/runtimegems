require 'yaml'
require 'json'
require 'net/http'
require 'uri'

REQUIRED_FIELDS = %w[name repo path ref description].freeze

# ------------------------------------------------------------------
# GitHub API helpers
# ------------------------------------------------------------------

def github_token
  ENV['GITHUB_TOKEN']
end

def github_api_get(path)
  uri = URI("https://api.github.com#{path}")
  req = Net::HTTP::Get.new(uri)
  req['Accept']     = 'application/vnd.github+json'
  req['User-Agent'] = 'runtimegems-updater'
  req['Authorization'] = "Bearer #{github_token}" if github_token

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
  [res.code.to_i, res.body]
end

def parse_repo_owner_name(repo_url)
  # e.g. https://github.com/picoruby/picoruby
  m = repo_url.match(%r{github\.com/([^/]+)/([^/]+?)(?:\.git)?$})
  raise "Cannot parse GitHub repo URL: #{repo_url}" unless m
  [m[1], m[2]]
end

# ------------------------------------------------------------------
# Validation
# ------------------------------------------------------------------

def validate_gem(data, filename)
  repo_url = data['repo']
  path     = data['path']
  ref      = data['ref']

  owner, repo_name = parse_repo_owner_name(repo_url)
  api_base = "/repos/#{owner}/#{repo_name}/contents/#{path}"
  ref_param = "?ref=#{ref}"

  # 1. repo/path is accessible
  code, body = github_api_get("#{api_base}#{ref_param}")
  unless code == 200
    raise "#{filename}: repo/path not accessible (HTTP #{code}): #{repo_url}/#{path} @ #{ref}"
  end

  # 2. mrbgem.rake exists and is syntax-valid Ruby
  rake_code, rake_body = github_api_get("#{api_base}/mrbgem.rake#{ref_param}")
  unless rake_code == 200
    raise "#{filename}: mrbgem.rake not found at #{path}"
  end
  rake_content = JSON.parse(rake_body)
  rake_source  = rake_content['encoding'] == 'base64' \
    ? rake_content['content'].unpack1('m') \
    : rake_content['content']
  begin
    RubyVM::AbstractSyntaxTree.parse(rake_source)
  rescue SyntaxError => e
    raise "#{filename}: mrbgem.rake has syntax error: #{e.message}"
  end

  # 3. mrblib directory exists with at least one .rb file directly under it
  mrblib_code, mrblib_body = github_api_get("#{api_base}/mrblib#{ref_param}")
  unless mrblib_code == 200
    raise "#{filename}: mrblib directory not found at #{path}"
  end
  entries = JSON.parse(mrblib_body)
  rb_files = entries.select { |e| e['type'] == 'file' && e['name'].end_with?('.rb') }
  if rb_files.empty?
    raise "#{filename}: mrblib contains no .rb files directly under #{path}/mrblib"
  end
end

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

top_dir    = File.expand_path('..', __dir__)
yaml_files = Dir.glob(File.join(top_dir, '*.yaml')).sort

gems = yaml_files.map do |file|
  data = YAML.load_file(file)
  REQUIRED_FIELDS.each do |field|
    if data[field].nil? || data[field].to_s.strip.empty?
      raise "#{File.basename(file)}: missing required field '#{field}'"
    end
  end

  validate_gem(data, File.basename(file))

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
