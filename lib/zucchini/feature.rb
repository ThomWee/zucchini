class Zucchini::Feature
  include Zucchini::Compiler
  include Zucchini::Device

  attr_accessor :path
  attr_accessor :device
  attr_accessor :stats
  attr_accessor :js_exception
  attr_accessor :js_stdout

  attr_reader :succeeded
  attr_reader :name

  def initialize(path)
    @path         = path
    @name         = File.basename(path)
    @device       = nil
    @succeeded    = false
    @js_exception = false
    @js_stdout = nil
  end

  def run_data_path
     "#{@path}/run_data"
  end

  def run_path
    "#{run_data_path}/Run\ 1"
  end

  def unmatched_pending_screenshots
    Dir.glob("#{@path}/pending/#{@device[:screen]}/[^0-9]*.png").sort.map do |file|
      screenshot = Zucchini::Screenshot.new(file, nil, nil, true)
      screenshot.test_path = File.expand_path(file)
      screenshot.diff = [:pending, "unmatched"]
      screenshot
    end
  end

  def screenshots(process = true)
    log = Zucchini::Log.new(run_path) if process && Zucchini::Log.exists?(run_path)
    
    @screenshots ||= Dir.glob("#{run_path}/*.png").sort.map do |file|
      next unless Zucchini::Screenshot.valid?(file)

      screenshot = Zucchini::Screenshot.new(file, @device, log)
      if process
        screenshot.mask
        screenshot.compare
      end
      screenshot
    end.compact + unmatched_pending_screenshots
  end

  def stats
    @stats ||= screenshots.inject({:passed => [], :failed => [], :pending => []}) do |stats, s|
      stats[s.diff[0]] << s
      stats
    end
  end

  def collect
    with_setup do
      `rm -rf #{run_data_path}/*`

      @js_stdout = nil
      begin
        @js_stdout = `instruments #{device_params(@device)} \
               -t "#{Zucchini::Config.template}" "#{Zucchini::Config.app}" \
               -e UIASCRIPT "#{compile_js(@device[:orientation])}" \
               -e UIARESULTSPATH "#{run_data_path}" #{Zucchini::Config.app_args} 2>&1`
        puts @js_stdout
        # Hack. Instruments don't issue error return codes when JS exceptions occur
        @js_exception = true if (@js_stdout.match /JavaScript error/) || (@js_stdout.match /Instruments\ .{0,5}\ Error\ :/ )
      ensure
        `rm -rf instrumentscli*.trace`
        Zucchini::Log.parse_automation_log(run_path)
      end
    end
  end

  def compare
    `rm -rf #{run_data_path}/Diff/*`
    @succeeded = !@js_exception && (stats[:failed].length == 0)
  end

  def with_setup
    setup = "#{@path}/setup.rb"
    if File.exists?(setup)
      require setup
      begin
        Setup.before { yield }
      ensure
        Setup.after
      end
    else
      yield
    end
  end

  def approve(reference_type)
    raise "Directory #{path} doesn't contain previous run data" unless File.exists?("#{run_data_path}/Run\ 1")

    screenshots(false).each do |s|
      reference_file_path = "#{File.dirname(s.file_path)}/../../#{reference_type}/#{device[:screen]}/#{s.file_name}"
      FileUtils.mkdir_p File.dirname(reference_file_path)
      @succeeded = FileUtils.copy_file(s.file_path, reference_file_path)
    end
  end
end
