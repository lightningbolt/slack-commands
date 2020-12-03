require 'yaml'

INSULTS = ActiveSupport::HashWithIndifferentAccess.new(
  YAML.load_file(File.join(Rails.root, 'config', 'insults.yml'))
)
