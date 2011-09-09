#!/usr/bin/env ruby
#
# amazon-auth-proxy.cgi:
#	Authentication Proxy Server of Amazon Product Advertising API.
#
# Copyright (C) 2009 TADA Tadashi <t@tdtds.jp>
# You can redistribute it and/or modify it under GPL2.
#

require 'uri'
require 'base64'
require 'digest/sha2'
require 'time'
require 'timeout'
require 'open-uri'
require 'erb'
include ERB::Util

# for ruby < 1.8.7
unless defined?( Object::tap )
	class Object
		def tap
			yield(self)
			self
		end
	end
end

module HMAC
	IPAD = [0x36] * 64
	OPAD = [0x5c] * 64

	module_function

	def sha256( key, message )
		ikey = IPAD.dup
		okey = OPAD.dup
		key = [].tap {|k| key.each_byte {|x| k << x}}
		key.size.times{|i|
			ikey[i] = key[i] ^ IPAD[i]
			okey[i] = key[i] ^ OPAD[i]
		}
		ik = ikey.pack( "C*" )
		ok = okey.pack( "C*" )
		value = Digest::SHA256.digest( ik + message )
		value = Digest::SHA256.digest( ok + value )
	end
end

def paapi( conf, params )
	xslt = false
	qs = [].tap {|q|
		params.each do |key, values|
			if key =~ /^(AWSAccessKeyId|SubscriptionId)$/
				q << "#{u key}=#{u conf['access_key']}"
			elsif key == 'Timestamp'
				# ignore this key
			else
				q << "#{u key}=#{u values[0]}"
				xslt = true if key == 'Style'
			end
		end
		unless params.keys.include?( 'AssociateTag' ) then
			q << "AssociateTag=#{u conf['default_aid']}"
		end
		q << "Timestamp=#{u DateTime.now.new_offset.strftime('%Y-%m-%dT%XZ') }"
	}.sort

	uri = URI.parse( conf[xslt ? 'xslt_entry_point' : 'entry_point'] )
	message = ['GET', uri.host, uri.path, qs * '&'] * "\n"
	begin
		require 'openssl'
		hash = OpenSSL::HMAC::digest( OpenSSL::Digest::SHA256.new, conf['secret_key'], message )
	rescue LoadError, NameError
		hash = HMAC::sha256( conf['secret_key'], message )
	end
	qs << "Signature=#{u [hash].pack( "m" ).chomp}"

	url = uri.to_s + '?' + qs * '&'
	return [302, url] if conf['use_redirect']

	timeout( 10 ) do
		return [200, open( url, &:read )]
	end
end

if __FILE__ == $0 then
	require 'cgi'
	cgi = CGI::new
	
	require 'yaml'
	conf = YAML::load_file( 'amazon-auth-proxy.yaml' )

	begin
		status, body = paapi( conf, cgi.params )
		if status == 200 then
			print cgi.header(
				'status' => '200',
				'type' => 'text/xml;charset="UTF-8"'
			)
			print body
		elsif 302
			print cgi.header(
				'status' => '302',
				'location' => body
			)
			puts "\n\n"
		end
	rescue
		print "Status: 500\nContent-Type: text/plain\n\n"
		print $!.message
	end
end

