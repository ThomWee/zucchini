require 'yaml'

module Zucchini
  class Config

    def self.sim_guid
      @@sim_guid
    end
    
    def self.sim_guid=(guid)
      @@sim_guid = guid
    end

    def self.base_path
      @@base_path
    end

    def self.base_path=(base_path)
      @@base_path = base_path
      @@config    = YAML::load(ERB::new(File::read("#{base_path}/support/config.yml")).result)
      @@default_device_name = nil
      devices.each do |device_name, device|
        if device['default']
          raise "Default device already provided" if @@default_device_name
          @@default_device_name = device_name
        end
      end
    end

    def self.app
      device_name  = ENV['ZUCCHINI_DEVICE'] || @@default_device_name
      device       = devices[device_name]
      
      if !device['bundle_id'].nil?
        device['bundle_id']
      else
        app_path = File.absolute_path(device['app'] || @@config['app'] || ENV['ZUCCHINI_APP'])

        if (device_name == 'iOS Simulator' || device['simulator']) && !File.exists?(app_path)
          raise "Can't find application at path #{app_path}"
        end
        app_path
      end
    end

    def self.app_args
      @@config['app_args']
    end

    def self.resolution_name(dimension)
      @@config['resolutions'][dimension.to_i]
    end

    def self.devices
      @@config['devices']
    end

    def self.default_device_name
      @@default_device_name
    end

    def self.device(device_name = nil)
      device_name ||= @@default_device_name
      raise "Neither default device nor ZUCCHINI_DEVICE environment variable was set" unless device_name
      raise "Device '#{device_name}' not listed in config.yml" unless (device = devices[device_name])
      {
        :name        => device_name,
        :udid        => device['UDID'],
        :screen      => device['screen'],
        :simulator   => device['simulator'],
        :orientation => device['orientation'] || 'portrait',
        
        :os_ver_id   => device['os_ver_id'],
        :sim_id      => device['sim_id'],
        :bunlde_id   => device['bundle_id'],
        :install_src => device['install_src'],
        :os_version  => device['os_version']
      }
    end

    def self.template
      locations = [
        `xcode-select -print-path`.gsub(/\n/, '') + "/Platforms/iPhoneOS.platform/Developer/Library/Instruments",
         "/Applications/Xcode.app/Contents/Applications/Instruments.app/Contents" # Xcode 4.5
      ].map do |start_path|
        path = "#{start_path}/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate"
        if !File.directory?(path)
          path = "#{start_path}/PlugIns/AutomationInstrument.xrplugin/Contents/Resources/Automation.tracetemplate"
        end
        path
      end

      locations.each { |path| return path if File.exists?(path) }
      raise "Can't find Instruments template (tried #{locations.join(', ')})"
    end

    def self.feature
      @@config['feature'] || {}
    end

    def self.feature_timeout
      feature['timeout'] || 0
    end

    def self.retry_attempts
      feature['retry_attempts'] || 1
    end
  end
end
