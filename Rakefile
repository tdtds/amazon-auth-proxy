begin
	require 'rake'
	require 'rspec/core/rake_task'

	desc 'Run the code in spec'
	RSpec::Core::RakeTask.new(:spec) do |t|
		t.pattern = "spec/*_spec.rb"
	end

	task :default => :spec
rescue LoadError
end
