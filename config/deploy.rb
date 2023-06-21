# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
# lock "~> 3.14.1"
lock "~> 3.17.0"

set :application, "video"
set :branch, 'main'
# set :stage, ->{gets.chomp()}
set :rails_env, fetch(:stage)
set :user, :ubuntu
append :linked_dirs, '.bundle'

set :repo_url, 'git@github.com:sumitdaksh/video.git' 


set :rvm1_map_bins, -> { fetch(:rvm_map_bins).to_a.concat(%w[rake gem bundle ruby]).uniq }
set :deploy_via, :remote_cache
set :deploy_to, "/home/deploy/apps/#{fetch(:application)}"
set :pty, true
set :bundle_binstubs, -> { shared_path.join('bin') }

set :linked_files, %w{config/database.yml}

set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads node_modules client/node_modules}
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads node_modules client/node_modules public/assets public/packs]
set :rvm_ruby_version, 'ruby-3.2.2@video' # Edit this if you are using MRI Ruby

set :sidekiq_role, :app
set :sidekiq_config, "#{current_path}/config/sidekiq.yml"
set :sidekiq_default_hooks, true
set :sidekiq_pid, File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') # ensure this path exists in production before deploying.
set :sidekiq_env, fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
set :sidekiq_log, File.join(shared_path, 'log', 'sidekiq.log')
set :sidekiq_service_unit_user, fetch(:user)
set :use_sudo, false

# namespace :git do
# desc 'aasas'
# task :check do

# end

# end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
        puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      invoke 'deploy'
    end
  end

  desc "Restart sidekiq"
  task :restart_sidekiq do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end

  after  :finishing,    :cleanup
  after  :finishing,    :'deploy:restart_sidekiq'
end
