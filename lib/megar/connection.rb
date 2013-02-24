require 'net/http'
require 'net/https'
require 'uri'
require 'json'

# A simple module to encapsulate network interation
#
module Megar::Connection

  attr_accessor :sid

  # Returns the current session sequence_number.
  # On first request, it is initialised to a random integer.
  def sequence_number
    @sequence_number ||= rand(0xFFFFFFFF)
  end

  # Set the secuence number to +value+ (Fixnum)
  def sequence_number=(value)
    @sequence_number = value
  end

  # Command: increments and returns the next sequence number
  def next_sequence_number!
    sequence_number && @sequence_number += 1
  end

  # There seem to be a number of regional API enpoints,
  # but not sure if there is any guidance yet as to which you should use.
  # Known endpoints: https://g.api.mega.co.nz/cs, https://eu.api.mega.co.nz/cs
  DEFAULT_API_ENDPOINT = 'https://eu.api.mega.co.nz/cs'

  # Return the API endpoint url (String) - defaults to DEFAULT_API_ENDPOINT
  def api_endpoint
    @api_endpoint ||= DEFAULT_API_ENDPOINT
  end

  # Set the API endpoint url to +value+ (String)
  def api_endpoint=(value)
    @api_endpoint = value
  end

  # Returns the API endpoint uri
  def api_uri
    @api_uri ||= URI.parse(api_endpoint)
  end

  # Command: Perform a single API request given +data+
  def api_request(data)
    params = {'id' => next_sequence_number!}
    params['sid'] = sid if sid
    json_data = [data].to_json

    response_data = get_api_response(params,json_data).first

    raise Megar::MegaRequestError.new(response_data) if response_data.is_a?(Fixnum)

    response_data
  end

  # Command: low-level method to actually perform the API request and return the JSON response.
  # Given +params+ Hash of query string parameters, and +data+ JSON data structure.
  # Note: there is no handling of network errors or timeouts - any exceptions will bubble up.
  def get_api_response(params,data)
    http = Net::HTTP.new(api_uri.host, api_uri.port)
    http.use_ssl = (api_uri.scheme == 'https')
    uri_path = api_uri.path.empty? ? '/' : api_uri.path
    uri_path << hash_to_query_string(params)
    response = http.post(uri_path,data)
    JSON.parse(response.body)
  end
  protected :get_api_response

  # Returns Hash +h+ as an encoded query string '?a=b&c=d...'
  def hash_to_query_string(h)
    if qs = URI.escape(h.to_a.map{|e| e.join('=') }.join('&'))
      '?' + qs
    else
      ''
    end
  end
  protected :hash_to_query_string

end
