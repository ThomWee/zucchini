require 'fileutils'

module Zucchini
  module Compiler

    # Compile the feature Javascript file for UIAutomation
    #
    # @param orientation [String] initial device orientation, `portrait` or `landscape`
    # @return [String] path to a compiled js file
    def compile_js(orientation)
      js_path  = "#{run_data_path}/feature.js"
      lib_path = File.expand_path(File.dirname(__FILE__))

      coffee_src_paths = Dir.glob([
        "#{lib_path}/uia/**/*.coffee",
        "#{Zucchini::Config.base_path}/support/lib/*.coffee",
        "#{Zucchini::Config.base_path}/support/screens/*.coffee",
        feature_coffee("#{path}/feature.zucchini", orientation)
      ]).join ' '

      "cat #{coffee_src_paths} | coffee --compile --stdio > #{js_path}".tap do |cmd|
        raise "Error compiling a feature file: #{cmd}" unless system(cmd)
      end

      concat("#{lib_path}/uia/lib", js_path)
      js_path
    end

    private

    # Wrap feature text into a call to Zucchini client side runner
    #
    # @param file [String] path to a feature file
    # @param orientation [String] initial device orientation
    # @return [String] path to the resulting CoffeeScript file
    def feature_coffee(file, orientation)
      cs_path = "#{run_data_path}/feature.coffee"

      File.open(cs_path, "w+") do |f|
        feature_text = File.read(file).gsub(/\#.+[\z\n]?/,"").gsub(/\n/, "\\n")
        f.write "Zucchini('#{feature_text}', '#{orientation}')"
      end
      cs_path
    end

    def concat(lib_path, js_path)
      tmp_file = "/tmp/feature.js"

      js_src = Dir.glob("#{lib_path}/*.js").inject([]) do |libs, f|
        libs << File.read(f)
      end.join(";\n")

      File.open(tmp_file, 'w') do |f|
        f.puts(js_src)
        f.puts(File.read(js_path))
      end

      FileUtils.mv(tmp_file, js_path)
    end
  end
end
