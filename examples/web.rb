require 'sinatra'
require 'citrus/core'

class ConsoleNotifier
  attr_reader :io

  def initialize(io = STDOUT)
    @io = io
  end

  def build_succeeded(build, output);     io.puts "[#{build.uuid}] Build has succeeded.";     end
  def build_failed(build, output);        io.puts "[#{build.uuid}] Build has failed.";        end
  def build_aborted(build, error) ;       io.puts "[#{build.uuid}] Build has been aborted.";  end
  def build_started(build);               io.puts "[#{build.uuid}] Build has started.";       end
  def build_output_received(build, data); io.print data; end
end

class QueuedBuilder
  include Citrus::Core

  attr_reader :queue, :service

  def initialize(queue, subscriber)
    workspace_builder    = WorkspaceBuilder.new
    configuration_loader = ConfigurationLoader.new
    test_runner          = TestRunner.new
    test_runner.add_subscriber(subscriber)
    @queue   = queue
    @service = ExecuteBuildService.new(workspace_builder, configuration_loader, test_runner)
    @service.add_subscriber(subscriber)
  end

  def run
    Thread.new do
      loop do
        build = queue.pop
        service.start(build)
      end
    end
  end
end

queue   = Queue.new
builder = QueuedBuilder.new(queue, ConsoleNotifier.new)
builder.run

post '/github_push' do
  service = CreateBuildService.new
  queue << service.create_from_github_push(params[:payload])
  status 200
end
