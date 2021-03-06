#!/usr/bin/env ruby

require 'daemons'
require 'yaml'
require 'etcd'

config = YAML.load_file(File.expand_path('../config.yml', __FILE__))
ME=`hostname -s`.chomp

class WhatsinstalledAgent
  def initialize(config)
    @config = config
    @ttl = config['settings'].fetch('ttl', 60)
    @etcd = Etcd.client(host: @config['settings']['info_server'], port: @config['settings'].fetch('port', 4001))
  end

  def git_version(path)
    if File.exists?(path)
      rev = %x(cd #{path} && git name-rev --tags --name-only $(git rev-parse HEAD))
      rev =~ /undefined/ ? %x(cd #{path} && git rev-parse --short HEAD) : rev
    else
      "not installed"
    end
  end

  def dpkg_version(package)
    version = %x(dpkg-query -W -f='${Version}' #{package})
    version = "not installed" unless $?.success?
    version
  end

  def timestamp(path)
    Time.at(File.stat(path).ctime).strftime('%D %T')
  end

  def set_app_version(app, path)
    @etcd.set("/apps/#{app}/#{ME}/version", value: git_version(path), ttl: @ttl)
  end

  def set_app_timestamp(app, path)
    @etcd.set("/apps/#{app}/#{ME}/timestamp", value: timestamp(path), ttl: @ttl)
  end

  def set_assay_version(assay, path)
    @etcd.set("/assays/#{assay}/#{ME}/version", value: git_version(path), ttl: @ttl)
  end

  def set_assay_timestamp(assay, path)
    @etcd.set("/assays/#{assay}/#{ME}/timestamp", value: timestamp(path), ttl: @ttl)
  end

  def set_package_version(package)
    @etcd.set("/packages/#{package}/#{ME}/version", value: dpkg_version(package), ttl: @ttl)
  end
end

Daemons.run_proc('whatsinstalled_agent.rb') do
  loop do
    begin
      agent = WhatsinstalledAgent.new(config)

      if config.has_key?('apps') and !config['apps'].empty?
        config['apps'].each do |app, path|
          agent.set_app_version(app, path)
          agent.set_app_timestamp(app, path)
        end
      end

      Dir.glob("#{config['assays']}/*/current").each do |path|
        assay = File.basename(File.dirname(path))
        agent.set_assay_version(assay, path)
        agent.set_assay_timestamp(assay, path)
      end

      config['packages'].each do |package|
        agent.set_package_version(package)
      end
    rescue
      puts "Could not connect to etcd."
    end
    sleep config['settings'].fetch('check_interval', 20)
  end
end
