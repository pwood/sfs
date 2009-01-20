# Provides a few useful object for interfacing with stopforumspam.com.
#
# Inspired by sfs.py by Kevan Carstensen for Python.
# http://isnotajoke.com/projects/sfs/
#
# Copyright (c) 2009 Peter Wood
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Load XML parsing module
begin
  require 'hpricot' # version 0.6
rescue LoadError
  require 'rubygems'
  require 'hpricot'
end

# Load HTTP library
require 'net/http'

# Require time for parsing.
require 'time'

module SFS
  class API
    @@sfs_uri = "www.stopforumspam.com/api"
    @@sfs_checks = { :ip => "ip",
                     :email => "email",
                     :username => "username" }

    @@sfs_checks.keys.each do |key|
      define_method("check_#{key}") do |*item|
	if (item.size == 1)
 	  return check(key, item[0], false)
	else
          return check(key, item[0], item[1])
	end
      end
    end

    attr_accessor :api_key, :sfs_uri, :sfs_checks

    def add (ip, email, username, api_key = nil)
      raise Exception, "No API Key Defined" if (!api_key && !self.api_key)
      raise Exception, "Not Yet Implemented"
    end

    private

    def check(type, item, advanced)
      raise Exception, "No #{type} provided!" if !item

      # Construct query URL.
      url = "http://#{@@sfs_uri}?#{@@sfs_checks[type]}=#{item}"

      # Construct request.
      request = Net::HTTP::Get.new(url)
      request["user-agent"] = "Ruby SFS::API by Peter Wood <peter+sfsapi@alastria.net>"

      # Prase URL
      uri = URI.parse(url)

      # Create HTTP object.
      http = Net::HTTP.new(uri.host, uri.port)

      # Attempt request
      begin
        http.start do
          result = http.request(request)

        case result
          when Net::HTTPSuccess
            return parse_result(result.body, advanced)
          else
            raise Exception, "Unable to retrieve from API, Net::HTTP issue."
          end
        end
      rescue Timeout::Error => e
        raise Exception, "Unable to retrieve from API, Timeout:Error."
      rescue => e
        raise Exception, "Unable to retrieve from API, Exception."
      end
    end

    def parse_result(result, advanced)
      doc = Hpricot.XML(result).at("response")

      raise Exception, "Invalid response from API, Invalid XML." if (!doc)

      raise Exception, "API failed to retrieve information." if (doc.attributes["success"] != "true")
  
      if ((doc/"appears").inner_text != "yes")
	if (!advanced)
          return false
	else
	  return false, nil
	end
      else
	if (!advanced)
          return (doc/"frequency").inner_text.to_i
	else
	  return (doc/"frequency").inner_text.to_i, Time.parse((doc/"lastseen").inner_text.to_s)
	end
      end
    end
  end
end
