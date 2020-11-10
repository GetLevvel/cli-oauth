# frozen_string_literal: true
# copied straight up from  MikeMcQuaid/strap
 
require "sinatra"
require "omniauth-github"
require "octokit"
require "securerandom"
require "rack/protection"
require "awesome_print" if ENV["RACK_ENV"] == "development"

GITHUB_KEY = ENV["GITHUB_KEY"]
GITHUB_SECRET = ENV["GITHUB_SECRET"]
SESSION_SECRET = ENV["SESSION_SECRET"] || SecureRandom.hex
CLI_ISSUES_URL = ENV["CLI_ISSUES_URL"]
CUSTOM_HOMEBREW_TAP = ENV["CUSTOM_HOMEBREW_TAP"]
CUSTOM_BREW_COMMAND = ENV["CUSTOM_BREW_COMMAND"]

set :sessions, secret: SESSION_SECRET

use OmniAuth::Builder do
  options = { scope: "user:email,repo,workflow" }
  options[:provider_ignores_state] = true if ENV["RACK_ENV"] == "development"
  provider :github, GITHUB_KEY, GITHUB_SECRET, options
end

use Rack::Protection, use: %i[authenticity_token cookie_tossing form_token
                              remote_referrer strict_transport]

get "/auth/github/callback" do
  auth = request.env["omniauth.auth"]
  session[:auth] = {
    "info"        => auth["info"],
    "credentials" => auth["credentials"],
  }

  return_to = session.delete :return_to
  return_to = "/" if !return_to || return_to.empty?
  redirect to return_to
end

get "/" do
  if request.scheme == "http" && ENV["RACK_ENV"] != "development"
    redirect to "https://#{request.host}#{request.fullpath}"
  end

  debugging_text = if CLI_ISSUES_URL.to_s.empty?
    "try to debug it yourself"
  else
    %Q{file an issue at <a href="#{CLI_ISSUES_URL}">#{CLI_ISSUES_URL}</a>}
  end

  @title = "Levvel CLI"
  @text = <<~HTML
    <p class="font-italic">⚠️ The lvl cli project only works with MacOS and Linux natively.  Windows 
    is supported, but you will have to enable 
    <a href="https://docs.microsoft.com/en-us/windows/wsl/install-win10" target="_blank">Windows Subsystem for Linux</a>
    </p>
    <p class="font-italic">💡 Note that in order to run the lvl cli, you must have 
      <a href="https://nodejs.org/en/download/" target="_blank">node.js</a> 
      v 10.5 (or greater), 
      <a href="https://classic.yarnpkg.com/en/docs/install/#mac-stable" target="_blank">yarn</a>
      , and 
      <a href="https://git-scm.com/book/en/v2/Getting-Started-Installing-Git" target="_blank">git</a>
       installed
    <div class="ml-3">
    <h5 class="pb-2">Installation Instructions</h5>
    <ol>
      <li>
        <a class="no-underline" href="/install-cli.sh">
          <button type="button" class="btn btn-sm">
            Download the <code>install-cli.sh</code>
          </button>
        </a>
        that's been customised for your GitHub user (or
        <a href="/install-cli.sh?text=1">view it</a>
        first). This will prompt for access to your email, public and private
        repositories; this is in order to allow you to pull resources from other GetLevvel. 
        Please keep this token safe since it allows actions to be made to GetLevvel's repositories
        on your behalf!
      </li>
      <li>
        Run <code>install-cli.sh</code> in Terminal.app (or any other bash supported command line) 
        with <code>bash ~/Downloads/install-cli.sh</code>.
      </li>
      <li>
        Delete the customised <code>install-cli.sh</code> (it has a GitHub token
        in it) in Terminal.app with
        <code>rm -f ~/Downloads/install-cli.sh</code>
      </li>
      <li>
        Run <code>lvl -h</code> to see the palette of available commands. Happy developing!
      </li>
    </ol>
    </div>
    <p class="font-italic">
      💡 If you run into an error or have questions, you can ping the 
      #lvl_cli channel in slack and someone will assist you. If you find a problem, please 
      consider filing an 
      <a href="https://github.com/GetLevvel/lvl_cli/issues" target="_blank">
      issue
      </a> in the lvl-cli repository.
    </p>
  HTML
  erb :root
end

get "/install-cli.sh" do
  auth = session[:auth]

  if !auth && GITHUB_KEY && GITHUB_SECRET
    query = request.query_string
    query = "?#{query}" if query && !query.empty?
    session[:return_to] = "#{request.path}#{query}"
    redirect to "/auth/github"
  end

  script = File.expand_path("#{File.dirname(__FILE__)}/../bin/install-cli.sh")
  content = IO.read(script)

  set_variables = { CLI_ISSUES_URL: CLI_ISSUES_URL }
  unset_variables = {}

  if CUSTOM_HOMEBREW_TAP
    unset_variables[:CUSTOM_HOMEBREW_TAP] = CUSTOM_HOMEBREW_TAP
  end

  if CUSTOM_BREW_COMMAND
    unset_variables[:CUSTOM_BREW_COMMAND] = CUSTOM_BREW_COMMAND
  end

  if auth
    unset_variables.merge! CLI_GIT_NAME:     auth["info"]["name"],
                           CLI_GIT_EMAIL:    auth["info"]["email"],
                           CLI_GITHUB_USER:  auth["info"]["nickname"],
                           CLI_GITHUB_TOKEN: auth["credentials"]["token"],
                           CLI_LOG_TOKEN:    ENV["LVL_CLI_LOG_TOKEN"]
  end

  env_sub(content, set_variables, set: true)
  env_sub(content, unset_variables, set: false)

  # Manually set X-Frame-Options because Rack::Protection won't set it on
  # non-HTML files:
  # https://github.com/sinatra/sinatra/blob/v2.0.7/rack-protection/lib/rack/protection/frame_options.rb#L32
  headers["X-Frame-Options"] = "DENY"
  content_type = if params["text"]
    "text/plain"
  else
    "application/octet-stream"
  end
  erb content, content_type: content_type
end

get "/install-cli-win.sh" do
  auth = session[:auth]

  if !auth && GITHUB_KEY && GITHUB_SECRET
    query = request.query_string
    query = "?#{query}" if query && !query.empty?
    session[:return_to] = "#{request.path}#{query}"
    redirect to "/auth/github"
  end

  script = File.expand_path("#{File.dirname(__FILE__)}/../bin/install-cli-win.sh")
  content = IO.read(script)

  unset_variables = {}

  if auth
    unset_variables.merge! CLI_GIT_NAME:     auth["info"]["name"],
                           CLI_GIT_EMAIL:    auth["info"]["email"],
                           CLI_GITHUB_USER:  auth["info"]["nickname"],
                           CLI_GITHUB_TOKEN: auth["credentials"]["token"],
                           CLI_LOG_TOKEN:    ENV["LVL_CLI_LOG_TOKEN"]
  end

  env_sub(content, unset_variables, set: false)

  # Manually set X-Frame-Options because Rack::Protection won't set it on
  # non-HTML files:
  # https://github.com/sinatra/sinatra/blob/v2.0.7/rack-protection/lib/rack/protection/frame_options.rb#L32
  headers["X-Frame-Options"] = "DENY"
  content_type = if params["text"]
    "text/plain"
  else
    "application/octet-stream"
  end
  erb content, content_type: content_type
end

get "/install-cli-win.cmd" do
  auth = session[:auth]

  if !auth && GITHUB_KEY && GITHUB_SECRET
    query = request.query_string
    query = "?#{query}" if query && !query.empty?
    session[:return_to] = "#{request.path}#{query}"
    redirect to "/auth/github"
  end

  script = File.expand_path("#{File.dirname(__FILE__)}/../bin/install-cli-win.cmd")
  content = IO.read(script)

  unset_variables = {}

  if auth
    unset_variables.merge! CLI_GIT_NAME:     auth["info"]["name"],
                           CLI_GIT_EMAIL:    auth["info"]["email"],
                           CLI_GITHUB_USER:  auth["info"]["nickname"],
                           CLI_GITHUB_TOKEN: auth["credentials"]["token"],
                           CLI_LOG_TOKEN:    ENV["LVL_CLI_LOG_TOKEN"]
  end

  env_sub(content, unset_variables, set: false)

  # Manually set X-Frame-Options because Rack::Protection won't set it on
  # non-HTML files:
  # https://github.com/sinatra/sinatra/blob/v2.0.7/rack-protection/lib/rack/protection/frame_options.rb#L32
  headers["X-Frame-Options"] = "DENY"
  content_type = if params["text"]
    "text/plain"
  else
    "application/octet-stream"
  end
  erb content, content_type: content_type
end

private

def env_sub(content, variables, set:)
  variables.each do |key, value|
    next if value.to_s.empty?
    regex = if set
      /^#{key}='.*'$/
    else
      /# #{key}=$/
    end
    escaped_value = value.gsub(/'/, "\\\\\\\\'")
    content.gsub!(regex, "#{key}='#{escaped_value}'")
  end
end
