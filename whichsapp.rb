#!/usr/bin/env ruby

require 'yaml'
require 'etcd'

class Whichsapp
  def initialize
    @config = YAML.load_file(File.expand_path('../config.yml', __FILE__))
    @etcd = Etcd.client(host: @config['settings']['info_server'], port: @config['settings'].fetch('port', 4001))
  end

  def dirname(dir)
    File.basename dir.key
  end

  def version_of(key)
    @etcd.get("#{key}/version").value.chomp
  end

  def ts_of(key)
    @etcd.get("#{key}/ts").value.chomp
  end

  def app_versions
    apps = Hash.new
    @etcd.get('/apps').children.each do |app|
      puts app
      @etcd.get(app.key).children.each do |server|
        apps["#{dirname(app)}"].concat({ "#{dirname(server)}" => { "version" => version_of(server.key), "ts" => ts_of(server.key) } })
      end
    end
  end
end

puts Whichsapp.new.app_versions.inspect

# require 'sinatra/base'
# require 'sinatra/config_file'
# require 'etcd'
# require 'yaml'
#
# class Whichsapp < Sinatra::Base
#   register Sinatra::ConfigFile
#   config_file File.expand_path('../config.yml', __FILE__)
#
#   configure :production, :development do
#     enable :logging
#   end
#
#   before do
#     @etcd = Etcd.client(host: settings['settings']['info_server'], port: 4001)
#   end
#
#   get '/apps' do
#     @etcd.get('/apps').inspect.to_s
#     #erb :page, :locals => { :page => 'apps', :key => @etcd.get('/apps/') }
#   end
#
#   # get '/assays' do
#   #   erb :page, :locals => { :page => 'assays', :key => @etcd.get('/assays/') }
#   # end
#   #
#   # get '/packages' do
#   #   erb :page, :locals => { :page => 'packages', :key => @etcd.get('/packages/') }
#   # end
#
#   run! if app_file == $0
# end
