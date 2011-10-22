#
# amazon-auth-proxy for sinatra
#
# Copyright (C) 2011 TADA Tadashi <t@tdtds.jp>
# You can redistribute it and/or modify it under GPL.
#
load 'amazon-auth-proxy.cgi'
require 'yaml'
require 'sinatra/base'

class AmazonAuthProxyApp < Sinatra::Base
	def initialize
		@conf = YAML::load_file( 'amazon-auth-proxy.yaml' )
		super
	end

	def make_conf( country )
		conf = {}
		conf['access_key'] = @conf['access_key']
		conf['secret_key'] = @conf['secret_key']
		conf['entry_point'] = @conf['entry_point'][country]
		conf['xslt_entry_point'] = @conf['xslt_entry_point'][country]
		conf['default_aid'] = @conf['aid'][country]
		conf['use_redirect'] = true
		conf
	end

	get '/' do
		return "access to #{@conf['aid'].keys.map{|a| "/#{a}/"}.join(', ')} with query for Amazon."
	end

	get '/*/' do
		country = params[:splat][0]
		return 400, "400 Bad request: '#{country}' not supported." unless @conf['aid'].keys.index( country )

		aparams = {}
		params.each do |k, v|
			aparams[k] = [v] unless k == 'splat'
		end
		begin
			status, body = paapi( make_conf( country ), aparams )
		rescue ArgumentError
			return 400, "400 Bad request: #{$!}"
		end
		redirect body, 302
	end

	get '/rpaproxy.yaml' do
		return 200, {'Content-Type' => 'text/yaml'}, {'locales' => @conf['aid'].keys}.to_yaml
	end
end
