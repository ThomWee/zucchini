require 'nokogiri'

module Zucchini::Reporter
  class JUnit

    def self.generate(features, report_path)

      doc = Nokogiri::XML::Document.new()
      root = Nokogiri::XML::Element.new('testsuites', doc)
      doc.add_child(root)

      suite_id = 0

      features.each do |f|
        suite = Nokogiri::XML::Element.new('testsuite', doc)
        suite['id'] = suite_id
        suite['package'] = f.name
        suite['hostname'] = ENV['ZUCCHINI_DEVICE']
        suite['name'] = f.name
        suite['tests'] = 1 + f.stats[:failed].length + f.stats[:passed].length #add 1 for whether or not js completed successfully
        suite['failures'] = f.stats[:failed].length
        suite['errors'] = (f.js_exception ? 1 : 0)
        suite['time'] = (f.js_duration ? f.js_duration : 0)
        suite['timestamp'] = Time.now.utc.iso8601.gsub!(/Z$/, '')

        suite_props = Nokogiri::XML::Element.new('properties', doc)
        suite.add_child(suite_props)


        # Report a single test case for whether or not the suite execution passed
        test_case = Nokogiri::XML::Element.new('testcase', doc)
        test_case['name'] = 'Feature Execution'
        test_case['classname'] = f.name
        test_case['time'] = 0

        if f.js_exception
          error = Nokogiri::XML::Element.new('error', doc)
          error['type'] = 'Uncaught Javascript Exception'
          test_case.add_child(error)
        end

        suite.add_child(test_case)


        f.screenshots.each_with_index do |s, j|
          failed  = s.diff[0] == :failed
          #pending = s.diff[0] == :pending

          test_case = Nokogiri::XML::Element.new('testcase', doc)
          test_case['name'] = s.file_name
          test_case['classname'] = s.file_path
          test_case['time'] = 0

          if failed
            error = Nokogiri::XML::Element.new('failure', doc)
            error['message'] = "#{s.diff[0]} does not match #{s.diff[1]}"
            error['type'] = 'Screenshot not matching'
            test_case.add_child(error)
          end

          suite.add_child(test_case)
        end

        stdout = (f.succeeded ? f.js_stdout.join("\n") : '')
        stderr = (!f.succeeded && f.js_stdout ? f.js_stdout.join("\n") : '')

        suite.add_child("<system-out>#{doc.create_cdata(stdout)}</system-out>")
        suite.add_child("<system-err>#{doc.create_cdata(stderr)}</system-err>")

        root.add_child(suite)

        suite_id += 1
      end

      File.open(report_path, 'w+') do |io|
         io.write(doc.to_xml)
      end

      File.read(report_path) + "\nJUnit report generated to #{report_path}"


    end

  end
end