class Zucchini::Runner < Zucchini::Detector
  include Zucchini::Device
  
  parameter "PATH", "a path to feature or a directory"

  option %W(-c --collect), :flag, "only collect the screenshots from the device"
  option %W(-p --compare), :flag, "perform screenshots comparison based on the last collection"
  option %W(-s --silent),  :flag, "do not open the report"
  option "--ci",           :flag, "produce a CI version of the report after comparison"

  option %W(-r --reports-dir), "DIR", "specify the directory for generated reports" , :default => '/tmp'

  def run_command
    compare_threads = {}
    retry_attempts = Zucchini::Config.retry_attempts
    feature_timeout = Zucchini::Config.feature_timeout

    if is_simulator? @device
      if @device[:sim_id]
        install_sim(@device[:os_ver_id], @device[:sim_id])
      end

      install_app(File.absolute_path(@device[:install_src]))
      start_simulator(@device)
    end

    features.each do |f|
      puts "------- starting feature #{f.name}---------"
      puts "  retry attempts: #{retry_attempts}"
      puts " feature timeout: #{feature_timeout}"

      f.device = @device

      if    collect? then f.collect(retry_attempts, feature_timeout)
      elsif compare? then f.compare
      else  f.collect(retry_attempts, feature_timeout); compare_threads[f.name] = Thread.new { f.compare }
      end
      puts "------- ending feature #{f.name}---------"
    end

    if @device[:sim_id]
      uninstall_sim()
    end

    compare_threads.each { |name, t| t.abort_on_exception = true; t.join }

    unless (collect? && !compare?)
      report = Zucchini::Report.new(features, ci?, reports_dir)
      report.open unless silent?
    end

    features.inject(true){ |result, feature| result &= feature.succeeded }
  end
end
