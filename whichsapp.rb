#!/usr/bin/env ruby

require 'yaml'
require 'etcd'
require 'sinatra'

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

  def get_versions_and_timestamps(key)
    res = Hash.new
    self.get_children(key).each do |app|
      res[name_of(app)] = Hash.new
      self.get_children(app).each do |server|
        res[name_of(app)][name_of(server)] = { 'version' => self.get_version(server), 'timestamp' => self.get_timestamp(server) }
      end
    end
    res
  end

  def get_versions(key)
    res = Hash.new
    self.get_children(key).each do |app|
      res[name_of(app)] = Hash.new
      self.get_children(app).each do |server|
        res[name_of(app)][name_of(server)] = { 'version' => self.get_version(server) }
      end
    end
    res
  end

  def get_version(server)
    self.value_of("#{server}/version") rescue nil
  end

  def get_timestamp(server)
    self.value_of("#{server}/timestamp") rescue nil
  end

  def name_of(key)
    File.basename(key)
  end
end

get '/' do
  'this is the index'
end

get '/apps' do
  Whichsapp.new.get_versions_and_timestamps('/apps').to_json
end

get '/packages' do
  Whichsapp.new.get_versions('/packages').to_json
end

get '/assays' do
  Whichsapp.new.get_versions_and_timestamps('/assays').to_json
end