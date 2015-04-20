#!/usr/bin/env ruby

require 'sinatra/base'
require 'sinatra/config_file'
require 'etcd'
require 'yaml'

class Whichsapp < Sinatra::Base
  register Sinatra::ConfigFile
  config_file File.expand_path('../config.yml', __FILE__)

  configure :production, :development do
    enable :logging
  end

  before do
    @etcd = Etcd.client(host: settings['settings']['info_server'], port: 4001)
  end

  get '/apps' do
    @etcd.get('/apps').inspect.to_s
    #erb :page, :locals => { :page => 'apps', :key => @etcd.get('/apps/') }
  end

  # get '/assays' do
  #   erb :page, :locals => { :page => 'assays', :key => @etcd.get('/assays/') }
  # end
  #
  # get '/packages' do
  #   erb :page, :locals => { :page => 'packages', :key => @etcd.get('/packages/') }
  # end

  run! if app_file == $0
end
