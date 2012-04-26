lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$:.unshift(lib) unless $:.include?('lib') || $:.include?(lib)

$:.unshift(File.dirname(__FILE__) + '/lib')

if defined? Gem
  Gem.source_index
  gem 'bundler'
else
  require 'rubygems'
end
require 'bundler'
Bundler.setup

require 'test/unit'
require 'active_support'
require 'action_controller'
require 'action_view'
require 'action_view/testing/resolvers'

require 'prototype-rails/on_load_action_controller'
require 'prototype-rails/on_load_action_view'

FIXTURE_LOAD_PATH = File.join(File.dirname(__FILE__), 'fixtures')
FIXTURES = Pathname.new(FIXTURE_LOAD_PATH)


module SetupOnce
  extend ActiveSupport::Concern

  included do
    cattr_accessor :setup_once_block
    self.setup_once_block = nil

    setup :run_setup_once
  end

  module ClassMethods
    def setup_once(&block)
      self.setup_once_block = block
    end
  end

  private
    def run_setup_once
      if self.setup_once_block
        self.setup_once_block.call
        self.setup_once_block = nil
      end
    end
end

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

module ActiveSupport
  class TestCase
    include SetupOnce
    # Hold off drawing routes until all the possible controller classes
    # have been loaded.
    setup_once do
      SharedTestRoutes.draw do
        match ':controller(/:action)'
      end

      ActionDispatch::IntegrationTest.app.routes.draw do
        match ':controller(/:action)'
      end
    end
  end
end

class RoutedRackApp
  attr_reader :routes

  def initialize(routes, &blk)
    @routes = routes
    @stack = ActionDispatch::MiddlewareStack.new(&blk).build(@routes)
  end

  def call(env)
    @stack.call(env)
  end
end

class BasicController
  attr_accessor :request

  def config
    @config ||= ActiveSupport::InheritableOptions.new(ActionController::Base.config).tap do |config|
      # VIEW TODO: View tests should not require a controller
      public_dir = File.expand_path("../fixtures/public", __FILE__)
      config.assets_dir = public_dir
      config.javascripts_dir = "#{public_dir}/javascripts"
      config.stylesheets_dir = "#{public_dir}/stylesheets"
      config
    end
  end
end

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  setup do
    @routes = SharedTestRoutes
  end

  def self.build_app(routes = nil)
    RoutedRackApp.new(routes || ActionDispatch::Routing::RouteSet.new) do |middleware|
      middleware.use "ActionDispatch::ShowExceptions", ActionDispatch::PublicExceptions.new("#{FIXTURE_LOAD_PATH}/public")
      middleware.use "ActionDispatch::Callbacks"
      middleware.use "ActionDispatch::ParamsParser"
      middleware.use "ActionDispatch::Cookies"
      middleware.use "ActionDispatch::Flash"
      middleware.use "ActionDispatch::Head"
      yield(middleware) if block_given?
    end
  end

  self.app = build_app

  # Stub Rails dispatcher so it does not get controller references and
  # simply return the controller#action as Rack::Body.
  class StubDispatcher < ::ActionDispatch::Routing::RouteSet::Dispatcher
    protected
    def controller_reference(controller_param)
      controller_param
    end

    def dispatch(controller, action, env)
      [200, {'Content-Type' => 'text/html'}, ["#{controller}##{action}"]]
    end
  end

  def self.stub_controllers
    old_dispatcher = ActionDispatch::Routing::RouteSet::Dispatcher
    ActionDispatch::Routing::RouteSet.module_eval { remove_const :Dispatcher }
    ActionDispatch::Routing::RouteSet.module_eval { const_set :Dispatcher, StubDispatcher }
    yield ActionDispatch::Routing::RouteSet.new
  ensure
    ActionDispatch::Routing::RouteSet.module_eval { remove_const :Dispatcher }
    ActionDispatch::Routing::RouteSet.module_eval { const_set :Dispatcher, old_dispatcher }
  end

  def with_routing(&block)
    temporary_routes = ActionDispatch::Routing::RouteSet.new
    old_app, self.class.app = self.class.app, self.class.build_app(temporary_routes)
    old_routes = SharedTestRoutes
    silence_warnings { Object.const_set(:SharedTestRoutes, temporary_routes) }

    yield temporary_routes
  ensure
    self.class.app = old_app
    silence_warnings { Object.const_set(:SharedTestRoutes, old_routes) }
  end

  def with_autoload_path(path)
    path = File.join(File.dirname(__FILE__), "fixtures", path)
    if ActiveSupport::Dependencies.autoload_paths.include?(path)
      yield
    else
      begin
        ActiveSupport::Dependencies.autoload_paths << path
        yield
      ensure
        ActiveSupport::Dependencies.autoload_paths.reject! {|p| p == path}
        ActiveSupport::Dependencies.clear
      end
    end
  end
end

# Temporary base class
class Rack::TestCase < ActionDispatch::IntegrationTest
  def self.testing(klass = nil)
    if klass
      @testing = "/#{klass.name.underscore}".sub!(/_controller$/, '')
    else
      @testing
    end
  end

  def get(thing, *args)
    if thing.is_a?(Symbol)
      super("#{self.class.testing}/#{thing}", *args)
    else
      super
    end
  end

  def assert_body(body)
    assert_equal body, Array.wrap(response.body).join
  end

  def assert_status(code)
    assert_equal code, response.status
  end

  def assert_response(body, status = 200, headers = {})
    assert_body   body
    assert_status status
    headers.each do |header, value|
      assert_header header, value
    end
  end

  def assert_content_type(type)
    assert_equal type, response.headers["Content-Type"]
  end

  def assert_header(name, value)
    assert_equal value, response.headers[name]
  end
end

module ActionController
  class Base
    include ActionController::Testing
    # This stub emulates the Railtie including the URL helpers from a Rails application
    include SharedTestRoutes.url_helpers

    self.view_paths = FIXTURE_LOAD_PATH

    def self.test_routes(&block)
      routes = ActionDispatch::Routing::RouteSet.new
      routes.draw(&block)
      include routes.url_helpers
    end
  end

  class TestCase
    include ActionDispatch::TestProcess

    setup do
      @routes = SharedTestRoutes
    end
  end
end
