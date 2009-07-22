#!/usr/bin/env ruby
#
# amazon-auth-proxy.fcgi:
#	Authentication Proxy Server of Amazon Product Advertising API.
#	(FastCGI version)
#
# Copyright (C) 2009 TADA Tadashi <t@tdtds.jp>
# Copyright (C) 2009 Taku YASUI <tach@debian.org>
# You can redistribute it and/or modify it under GPL2.
#

load 'amazon-auth-proxy.cgi'
require 'yaml'
require 'fcgi'

$conf = YAML::load_file( 'amazon-auth-proxy.yaml' )

FCGI.each_cgi do |cgi|
	begin
		status, body = paapi( $conf, cgi.params )
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

# vim: ts=3 sw=3 ft=ruby:
