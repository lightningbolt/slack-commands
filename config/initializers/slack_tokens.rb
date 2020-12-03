require 'yaml'

SLACK_TOKENS = ActiveSupport::HashWithIndifferentAccess.new(
  YAML.load_file(File.join(Rails.root, 'config', 'slack_tokens.yml'))
)
