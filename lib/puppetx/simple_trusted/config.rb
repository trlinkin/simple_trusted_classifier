require 'puppet/util/yaml'

module PuppetX
  module Simple_trusted
  end
end

class PuppetX::Simple_trusted::Config

  def self.defaults
    {
      :env_base_oid        => '1.3.6.1.4.1.34380.1.2.1',
      :role_oid            => '1.3.6.1.4.1.34380.1.2.2',
      :postfix_fact_name   => nil,
      :enforce_environment => true
    }
  end

  def self.load

    config_path = File.join(Puppet[:confdir], "simple_trusted.conf")

    if File.exists? config_path
      begin
        config_yaml = Puppet::Util::Yaml.load_file(config_path) || Hash.new
      rescue Puppet::Util::Yaml::YamlLoadError => detail
        raise Puppet::Error, "Could not parse YAML data for Simple Trusted classifier: #{detail}", detail.backtrace
      end
    else
      config_hash = Hash.new
    end

    # Symbolize the keys to ensure that the merge goes off easily
    config_yaml.keys.each do |key|
      config_yaml[(key.to_sym rescue key) || key] = config_yaml.delete(key)
    end

    # Merge the config yaml values with the defaults to get our resulting config hash
    allowed_keys = defaults.keys
    config_hash = defaults.merge(config_yaml).reject do |k, v|
      !(allowed_keys.include?(k))
    end

    # Sanitize configuration values
    config_hash[:env_base_oid] = config_hash[:env_base_oid].strip
    config_hash[:role_oid] = config_hash[:role_oid].strip

    self.new(config_hash)
  end

  def initialize(config_hash)
    @config = config_hash
  end

  def env_base_oid
    config[:env_base_oid]
  end

  def role_oid
    config[:role_oid]
  end

  def postfix_fact_name
    config[:postfix_fact_name]
  end

  def enforce_environment
    config[:enforce_environment]
  end
  private

  attr_reader :config
end
