require 'spec_helper'

describe Zucchini::Report do
  let(:device) do
    {
      :name   => "iPad 2",
      :screen => "ipad_ios5",
      :udid   => "rspec012345"
    }
  end

  let(:feature) do
    fake_screenshots = (1..7).to_a.map do |num|
      screenshot = Zucchini::Screenshot.new("0#{num}_screen_#{num}.png", device, nil)
      screenshot.diff = (num > 3) ? [:passed, nil] : [:failed, "120"]
      screenshot
    end

    feature = Zucchini::Feature.new("/my/sample/feature")
    feature.device = device
    feature.stub!(:screenshots).and_return(fake_screenshots)
    feature.send('js_exception='.to_sym, true)
    feature.send('js_duration='.to_sym, 10)
    feature
  end

  let(:reports_dir) { "/tmp/zucchini_rspec" }

  before do
    Zucchini::Report.any_instance.stub(:log)
    Zucchini::Report.new([feature], false, reports_dir)
  end
  after { FileUtils.rm_rf(reports_dir) }

  it "should produce a correct HTML report" do
    report = File.read("#{reports_dir}/zucchini_report.html")
    report.scan(/<dl class="passed.*screen/).length.should eq 4
    report.scan(/<dl class="failed.*screen/).length.should eq 3
  end

  it "should produce a correct TAP report" do
    expected = <<-END.gsub(/^ {6}/, '')
      1..1
      not ok 1 - feature
          1..7
          not ok 1 - 01_screen_1.png does not match (120)
          not ok 2 - 02_screen_2.png does not match (120)
          not ok 3 - 03_screen_3.png does not match (120)
          ok 4 - 04_screen_4.png
          ok 5 - 05_screen_5.png
          ok 6 - 06_screen_6.png
          ok 7 - 07_screen_7.png
          Bail out! Instruments run error
    END
    File.read("#{reports_dir}/zucchini.t").should eq expected
  end

  it "should produce a correct JUnit report" do
    report = File.read("#{reports_dir}/zucchini_report.xml")
    puts report

    report.scan(/<testsuite id/).length.should eq 1
    report.scan(/<testcase/).length.should eq 8
    report.scan(/<testsuite.*time="10"/).length.should eq 1

  end
end
