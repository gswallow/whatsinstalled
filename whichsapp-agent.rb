#!/usr/bin/env ruby

require 'daemons'
require 'yaml'
require 'etcd'

config = YAML.load_file(File.expand_path('../config.yml', __FILE__))
ME = `hostname -s`.chomp

Daemons.run_proc('whichsapp-agent.rb') do
  etcd = Etcd.client(host: config['settings']['info_server'], port: 4001)

  loop do
    def git_version(path)
      %x(test -e #{path} && ( cd #{path} && tag=$(git name-rev --tags --name-only $(git rev-parse HEAD)) ; [ "$tag" = "undefined" ] && git rev-parse --short HEAD || echo $tag ) || echo unknown)
    end

    def dpkg_version(package)
      %x(dpkg-query -W -f='${Version}' #{package} || echo missing)
    end

    def timestamp(path)
      Time.at(File.stat(path).ctime).strftime('%D %T')
    end

    def get_assays(path)
      Dir.glob("#{path}/*/current")
    end

    config['apps'].each do |app, path|
      etcd.set("/apps/#{app}/#{ME}/version", value: "#{git_version(path)}")
      etcd.set("/apps/#{app}/#{ME}/ts", value: "#{timestamp(path)}")
    end

    get_assays(config['assays']).each do |assay|
      name = File.basename(File.dirname(assay))
      etcd.set("/assays/#{name}/#{ME}/version", value: "#{git_version(assay)}")
      etcd.set("/assays/#{name}/#{ME}/ts", value: "#{timestamp(assay)}")
    end

    config['packages'].each do |package|
      etcd.set("/packages/#{package}/#{ME}/version", value: "#{dpkg_version(package)}")
    end

    sleep config['settings'].fetch('check_interval', 20)
  end
end
