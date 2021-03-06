require 'spec_helper'
describe Servme::Responder do

  let(:stubber) { Servme::Stubber.instance }
  let(:sinatra_app) { double }
  subject { Servme::Responder.new(sinatra_app, {}) }

  before { stubber.clear }

  context "when the responder receives a JSON request" do
    let(:params) { {"foo" => "bar"} }

    it "extracts and parses the json" do
      stubber.stub(:url => "/foo", :method => :get, :params => params, :response => {"bar" => "foo"})

      response = subject.respond(double(
        :path => "/foo",
        :request_method => "GET",
        :params => {},
        :env => {"CONTENT_TYPE"=>"application/json; charset=UTF-8"},
        :body => StringIO.new(params.to_json)
      ))

      JSON.parse(response.last).should == {"bar" => "foo"}
    end
  end

  it "returns stubs" do
    stubber.stub(:url => "/foo", :method => :get, :params => {}, :response => {"foo" => "bar"})

    response = subject.respond(double(
      :path => "/foo",
      :request_method => "GET",
      :params => {},
      :env => nil
    ))

    #response is a Rack response, its last entry is the response body
    JSON.parse(response.last).should == {"foo" => "bar"}
  end

  it "sends static files when there is no stub" do
    File.stub(:exists? => true)
    sinatra_app.should_receive(:send_file).with("dist/foo")

    subject.respond(double(
      :path => "/foo",
      :request_method => "GET",
      :params => nil
    ))
  end

  it "responds with the static index.html if the request is /" do
    sinatra_app.should_receive(:send_file).with("dist/index.html")

    subject.respond(double(
      :path => "/",
      :request_method => "GET",
      :params => nil
    ))
  end

  it "allows you to specify an alternate static_file_root_path" do
    responder = Servme::Responder.new(sinatra_app, :static_file_root_path => "public")
    File.stub(:exists? => true)
    sinatra_app.should_receive(:send_file).with("public/style.css")

    responder.respond(double(
      :path => "/style.css",
      :request_method => "GET",
      :params => nil
    ))
  end

  it "returns the stub if there is both a stub and a static file" do
    stubber.stub(:url => "/foo", :method => :get, :params => {}, :response => {"foo" => "bar"})
    File.stub(:exists? => true)
    sinatra_app.should_not_receive(:send_file)

    response = subject.respond(double(
      :path => "/foo",
      :request_method => "GET",
      :params => {},
      :env => nil
    ))

    JSON.parse(response.last).should == {"foo" => "bar"}
  end

  context "when the responder is configured with some static file options" do
    subject do
      Servme::Responder.new(sinatra_app,
                            {
                              :static_file_root_path => 'build',
                              :static_file_vdir => '/vdir',
                            })
    end

    it "returns a static file response for a file in a vdir" do
      File.stub(:exists? => true)
      sinatra_app.should_receive(:send_file).with("build/foo")

      subject.respond(double(
        :path => "/vdir/foo",
        :request_method => "GET",
        :params => nil
      ))
    end
  end
end
