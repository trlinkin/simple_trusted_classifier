require 'puppet/node'
require 'puppet/indirector/code'

begin
  # Try to require from the libdir
  require 'puppetx/simple_trusted/config'
rescue LoadError
  # Fallback to loading relatively from the modulepath
  require File.join(File.dirname(__FILE__), '../../..', 'puppetx/simple_trusted/config')
end

class Puppet::Node::Simple_trusted < Puppet::Indirector::Code
  desc "Use trusted data values from the client certificate to create classification."

  # Create node definition from trusted data.
  def find(request)
    node = Puppet::Node.new(request.key)
    node.fact_merge

    Puppet.debug "[Simple Trusted Classifier] Loading trusted data for simple classification of agent #{request.key}"
    facts = node.facts.values
    trusted = Puppet.lookup(:trusted_information) { Puppet::Context::TrustedInformation.local(request.key) }.to_h

    role = trusted['extensions'][config.role_oid]
    Puppet.debug "[Simple Trusted Classifier] Class #{role} will be declared into the catalog for agent #{request.key}" if role

    environment = trusted['extensions'][config.env_base_oid]
    if config.enforce_environment and environment.nil?
      raise ArgumentError, "[Simple Trusted Classifier] No environment found to be enforced at OID '#{config.env_base_oid}' for agent #{request.key}, cannot continue"
    end

    if config.postfix_fact_name and environment
      postfix = facts[config.postfix_fact_name]
      environment += "_#{postfix}" if postfix
    end

    Puppet.info "[Simple Trusted Classifier] Puppet environment being enforced for agent #{request.key} will be '#{environment}'" if environment

    # Add our values to the node object for catalog compilation to continue
    node.environment = environment || request.environment
    node.classes = [role] if role

    node
  end

  private

  def config
    @config ||= PuppetX::Simple_trusted::Config.load
  end
end
