require "json"
require "http/client"

module AutoTag
  extend self

  @@sha : String?
  @@owner : String?
  @@repo : String?
  @@remote_url : String?
  @@remote_matches : Regex::MatchData?

  TRUTHY_STRINGS = %w(t true y yes 1).flat_map do |str|
    [str.downcase, str.upcase, str.capitalize]
  end.uniq

  class CreateReleaseError < Exception; end

  class UniqueReleaseError < Exception; end

  class CodeNotMasterError < Exception; end

  def perform(count = 0)
    verify_master!
    verify_uniqueness!

    api_create_tag(Time.now.to_s("v%Y.%-m.%d.#{count}"))
  rescue CreateReleaseError
    perform(count + 1)
  end

  private def api_create_tag(tag_name : String) : Nil
    response = request "post" do |req|
      req.body = {
        "tag_name":         tag_name,
        "target_commitish": current_sha,
        "name":             "Release: #{tag_name}",
        "body":             "No Details",
        "draft":            false,
        "prerelease":       false,
      }.to_json
    end

    raise CreateReleaseError.new unless response.status_code == 201
  end

  private def request(method : String) : HTTP::Client::Response
    request(method) { }
  end

  private def request(method : String, path : String = "/repos/#{owner}/#{repo}/releases", &block : HTTP::Request -> _) : HTTP::Client::Response
    HTTP::Client.new(uri) do |http|
      request = HTTP::Request.new(method, path)
      request.headers["Authorization"] = "token #{github_token}"
      block.call request
      response = http.exec(request)
    end
  end

  private def uri
    URI.parse "https://api.github.com"
  end

  private def remote_url
    @@remote_url ||= `git config --get remote.origin.url`.strip
  end

  private def remote_matches
    @@remote_matches ||= remote_url.match(/.*@.*:(?<owner>.*)\/(?<repo>.*)\.git/) ||
                         remote_url.match(/(ssh|https):\/\/.*@.*\/(?<owner>.*)\/(?<repo>.*)\.git/)
  end

  private def owner
    @@owner ||= if matches = remote_matches
                  matches["owner"]
                end
  end

  private def repo
    @@repo ||= if matches = remote_matches
                 matches["repo"]
               end
  end

  private def github_token
    ENV["GITHUB_TOKEN"]
  end

  private def current_sha
    @@sha ||= `git rev-parse HEAD`.strip
  end

  private def verify_master!
    raise CodeNotMasterError.new "Code is not in master!" unless system "git merge-base --is-ancestor #{current_sha} master"
  end

  private def api_get_releases
    JSON.parse(request("get").body)
  end

  private def verify_uniqueness!
    if api_get_releases.any? { |release| release["target_commitish"] == current_sha }
      raise UniqueReleaseError.new "Code has already been released!"
    end
  end
end

AutoTag.perform
