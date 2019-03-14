# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

defmodule CH do
  def system_boolean( name ) do
    case String.downcase( System.get_env( name ) || "" ) do
      "true" -> true
      "yes" -> true
      "1" -> true
      "on" -> true
      _ -> false
    end
  end
end

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :sparqlex, key: :value
config :"mu-authorization",
  author: :"mu-semtech",
  log_delta_messages: CH.system_boolean("LOG_DELTA_MESSAGES"),
# and access this configuration in your application as:
#
#     Application.get_env(:sparql, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# config :logger,
#   compile_time_purge_level: :debug,
#   level: :info

config :logger,
  compile_time_purge_level: :debug,
  level: :warn

if Mix.env == :test do
  config :junit_formatter,
  report_dir: "/tmp/repo-example-test-results/exunit"
end

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

import_config "#{Mix.env}.exs"
