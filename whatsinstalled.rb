#!/usr/bin/env ruby

require 'yaml'
require 'etcd'
require 'sinatra'

class Whatsinstalled
  def initialize
    @config = YAML.load_file(File.expand_path('../config.yml', __FILE__))
    @etcd = Etcd.client(host: @config['settings']['info_server'], port: @config['settings'].fetch('port', 4001))
  end

  def get_children(key)
    parent = @etcd.get(key) rescue nil
    if parent.is_a?(Etcd::Response)
      children = parent.children
      @etcd.delete(key, recursive: true) if children.empty?
      children.collect { |c| c.key }
    end
  end

  def name_of(key)
    File.basename(key)
  end

  def value_of(key)
    res = @etcd.get(key)
    @etcd.delete(key) if res.value.empty?
    res.value.chomp
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
    version = self.value_of("#{server}/version") rescue nil
    @etcd.delete(server, recursive: true) if version.nil?
    version
  end

  def get_timestamp(server)
    timestamp = self.value_of("#{server}/timestamp") rescue nil
    @etcd.delete(server, recursive: true) if timestamp.nil?
    timestamp
  end

  def zap
    @etcd.get('/').children.collect do |child|
      @etcd.delete(child.key, recursive: true)
    end
  end
end

get '/' do
  erb 'Howdy.'
end

get '/apps' do
  erb :grid, :locals => { :res => Whatsinstalled.new.get_versions_and_timestamps('/apps') }
end

get '/packages' do
  erb :grid, :locals => { :res => Whatsinstalled.new.get_versions('/packages') }
end

get '/assays' do
  erb :grid, :locals => { :res => Whatsinstalled.new.get_versions_and_timestamps('/assays') }
end

get '/zap' do
  Whatsinstalled.new.zap
  erb 'Done.'
end
