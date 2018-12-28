# -*- coding: utf-8 -*-
load File.expand_path('../../amazon-auth-proxy.cgi', __FILE__)
require 'date'

RSpec::Matchers.define :starts_with do |expected|
	match do |actual|
		actual[0, expected.length] == expected
	end
end

describe 'paapi' do
	before :each do
		@conf = {
			'access_key' => 'SAMPLE_ACCESS_KEY',
			'secret_key' => 'SAMPLE_SECRET_KEY',
			'entry_point' => 'http://webservices.amazon.co.jp/onca/xml',
			'xslt_entry_point' => 'http://xml-jp.amznxslt.com/onca/xml',
			'default_aid' => 'cshs-22',
			'use_redirect' => true,
		}

		@req = {
			'Service' => ['AWSECommerceService'],
			'SubscriptionId' => ['12345678901234567890'],
			'Version' => ['2007-10-29'],
			'Operation' => ['ItemSearch'],
			'ResponseGroup' => ['Small'],
			'SearchIndex' => ['Books'],
			'Keywords' => ['Amazon'],
			'ItemPage' => ['1'],
		}
	end

	context '正常系' do
		it '返り値が2要素からなる' do
			expect(paapi( @conf, @req ).size).to eq(2)
		end

		it '返り値の第1要素(レスポンドコード)が302' do
			expect(paapi( @conf, @req )[0]).to eq 302
		end

		it '返り値の第2要素(redirect先)が正しいAWSリクエスト' do
			expect(paapi( @conf, @req )[1]).to starts_with 'http://webservices.amazon.co.jp/onca/xml?AssociateTag=cshs-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&SubscriptionId=SAMPLE_ACCESS_KEY&Timestamp='
		end

		it 'Styleを指定するとXSLTを使う' do
			@req['Style'] = ['dummy']
			expect(paapi( @conf, @req )[1]).to starts_with 'http://xml-jp.amznxslt.com/onca/xml?AssociateTag=cshs-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&Style=dummy&SubscriptionId=SAMPLE_ACCESS_KEY&Timestamp='
		end

		it 'AssociateTagを指定してあっても上書きする' do
			@req['AssociateTag'] = ['sample-22']
			expect(paapi( @conf, @req )[1]).to starts_with 'http://webservices.amazon.co.jp/onca/xml?AssociateTag=cshs-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&SubscriptionId=SAMPLE_ACCESS_KEY&Timestamp='
		end
	end

	context '異常系' do
		it 'AssociateTagがない場合に例外になる' do
			expect{ paapi( @conf.delete 'default_aid', @req ) }.to raise_error( ArgumentError )
		end
	end
end
