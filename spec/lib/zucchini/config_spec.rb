require 'spec_helper'

describe Zucchini::Config do
  describe ".base_path=" do
    it "should process the file through ERB" do
      Zucchini::Config.base_path = "spec/sample_setup"
      Zucchini::Config.device[:udid].should eql 'something_from_erb'
    end
  end

  describe ".app" do
    context "app environment variable" do
      before(:all) { ENV['ZUCCHINI_APP'] = 'foo.app' }

      it "should use environment variable if app not in config" do
        Zucchini::Config.base_path = "spec/sample_setup_3"
        Zucchini::Config.app.should include 'foo.app'
      end

      it "should not use environment variable if app in config" do
        Zucchini::Config.base_path = "spec/sample_setup"
        Zucchini::Config.app.should include 'MyApp.app'
      end
    end
  end

  describe ".device" do
    before(:all) { Zucchini::Config.base_path = "spec/sample_setup" }

    context "device present in config.yml" do
      it "should return the device hash" do
        Zucchini::Config.device("My iDevice").should eq({:name =>"My iDevice", :udid =>"lolffb28d74a6fraj2156090784avasc50725dd0", :screen =>"ipad_ios5", :simulator=>nil, :orientation=> 'portrait', :bundle_id=> 'de.my.app'})
      end
    end

    context "device not present in config.yml" do
      it "should raise an error" do
        expect { Zucchini::Config.device("My Android Phone")}.to raise_error "Device 'My Android Phone' not listed in config.yml"
      end
    end

    context "default device" do
      it "should use default device if device name argument is nil" do
        Zucchini::Config.device(nil)[:name].should eql "Default Device"
      end

      it "should raise error if no default device provided" do
        Zucchini::Config.base_path = "spec/sample_setup_2"
        expect { Zucchini::Config.device(nil) }.to raise_error "Neither default device nor ZUCCHINI_DEVICE environment variable was set"
      end
    end
  end
end
