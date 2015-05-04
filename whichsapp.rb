#!/usr/bin/env ruby

require 'yaml'
require 'etcd'

class Whichsapp
  def initialize
    @config = YAML.load_file(File.expand_path('../config.yml', __FILE__))
    @etcd = Etcd.client(host: @config['settings']['info_server'], port: @config['settings'].fetch('port', 4001))
  end

  def get_children(key)
    @etcd.get(key).children.collect { |c| c.key }
  end

  def value_of(key)
    @etcd.get(key).value.chomp
  end

  def get_apps
    self.get_children('/apps')
  end
end

puts Whichsapp.new.get_apps

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
