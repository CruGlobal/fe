require 'spec_helper'

describe "Root Page" do
  
  describe "GET /" do
    xit "success" do
      get root_path
      response.status.should be(200)
    end
  end
end
