# NOTE!
# Helicon Zoo module runs this script every time IIS application pool recycles.
# This has several reasons:
#   1. you may not have ability to run required commands yourself (on a shared hosting, for example);
#   2. specific URL for deployment may cause security issues;
#   3. application pool doesn't recycle often.
#
# If you're sure you don't need this file, it can be removed.

require 'rbconfig'

APP_ROOT = File.dirname( __FILE__ ).freeze
RUBY_BIN = RbConfig::CONFIG[ 'bindir' ].freeze
RACK_ENV = ( ENV[ 'RACK_ENV' ] || 'production' ).freeze

Dir.chdir( APP_ROOT )

def deploy( env, &block )
  return unless RACK_ENV == env.to_s
  block.call
end


def run( task, wrap = true )
  args = task.split
  cmd = args.shift

  ARGV.clear
  ARGV.unshift( *args )

  # We use 'load' because it doesn't spawn child ruby process,
  # which might be problematic in hosting environment.
  exe = File.join( RUBY_BIN, cmd )
  puts ">> #{exe} #{ARGV.inspect}"
  load( exe, wrap )
rescue Errno::EACCES => e
  puts 'Insufficient file system permissions.' +
    'Please make sure IIS application pool user has enough rights to access application files.' +
    "Usually Write permission isn't granted where it's needed. Exception: #{e}"
rescue Object => e
  puts e.to_s
  # Deploy tries to run all tasks. Some exceptions aren't relevant. See log if it matters.
end


deploy :development do
  run 'bundle install --path vendor/gems'
  run 'rake db:create --trace'
  run 'rake generate_session_store --trace'
  run 'rake db:migrate --trace'

  # TODO: add more development tasks here
end


deploy :production do
  run 'bundle install --local --path vendor/gems'
  run 'rake RAILS_ENV=production db:create --trace'
  run 'rake RAILS_ENV=production generate_session_store --trace'
  run 'rake RAILS_ENV=production db:migrate --trace'

  # TODO: add more production tasks here
end