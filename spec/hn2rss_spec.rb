require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 100

require 'hn2rss'

module HN2RSS
  HN2RSS.minimum_points = 1000

  describe HN do
    describe "#fetch_news" do
      let(:results) do
        subject.limit = 20
        subject.fetch_news
      end

      it "returns 20 items" do
        results.should have(20).items
      end

      it "returns news with an 'item' attribute" do
        results.all? { |r| r.should have_key 'item' }
      end
    end
  end

  describe RSS do
    let(:news) {
      [
        {"item"=>{"username"=>"hexis", "parent_sigid"=>nil, "domain"=>"amandablumwords.wordpress.com", "title"=>"Adria Richards, PyCon, and How We All Lost", "url"=>"https://amandablumwords.wordpress.com/2013/03/21/3/", "text"=>nil, "discussion"=>nil, "id"=>5419071, "parent_id"=>nil, "points"=>1004, "create_ts"=>"2013-03-21T21:13:58Z", "num_comments"=>392, "cache_ts"=>"2013-03-29T07:36:11Z", "_id"=>"5419071-b693d", "type"=>"submission", "_noindex"=>false, "_update_ts"=>1364542602595966}, "score"=>1.0},
        {"item"=>{"username"=>"afraidofadria", "parent_sigid"=>nil, "domain"=>"pastebin.com", "title"=>"The PyCon Incident", "url"=>"http://pastebin.com/JaNh0w5F", "text"=>nil, "discussion"=>nil, "id"=>5410515, "parent_id"=>nil, "points"=>1101, "create_ts"=>"2013-03-20T21:33:57Z", "num_comments"=>1038, "cache_ts"=>"2013-03-27T07:44:06Z", "_id"=>"5410515-10848", "type"=>"submission", "_noindex"=>false, "_update_ts"=>1364370293025758}, "score"=>1.0},
        {"item"=>{"username"=>"test", "parent_sigid"=>nil, "domain"=>"test.com", "title"=>nil, "url"=>"https://news.ycombinator.com/item?id=6805807", "text"=>"Hey, other comments are going to give you a few lines telling you to not quit", "discussion"=>nil, "id"=>6805807, "parent_id"=>nil, "points"=>1082, "create_ts"=>"2013-03-20T21:33:57Z", "num_comments"=>1038, "cache_ts"=>"2013-03-27T07:44:06Z", "_id"=>"5410515-10848", "type"=>"submission", "_noindex"=>false, "_update_ts"=>1364370293025758}, "score"=>1.0},
      ]
    }

    subject { RSS.new news }

    describe "#count" do
      it "returns the number of news" do
        subject.send(:count).should eq news.count
      end
    end

    describe "#average" do
      it "returns the average number of news per day" do
        DateTime.stub(:now).and_return(DateTime.parse "2013-03-22T01:11:47+02:00")
        subject.average.should eq "2.8 news per day"
      end

      it "returns the average number of news per month" do
        DateTime.stub(:now).and_return(DateTime.parse "2013-04-02T01:11:47+02:00")
        subject.average.should eq "7.5 news per month"
      end
    end

    describe "#rss" do
      subject { RSS.new(news).rss }

      it { should be_a String }

      it { should include "Last #{news.count} news over 1000 points" }
      it { should include "HN 1000" }
    end

    describe "#filename" do
      it "is \#{points}.atom" do
        File.basename(subject.send(:filename)).should eq "1000.atom"
      end
    end

    describe "#dump!" do
      let(:filename) { subject.send(:filename) }

      before do
        File.unlink filename if File.exist? filename
      end

      it "writes the RSS file" do
        expect {
          subject.dump!
        }.to change{File.exist? filename}.from(false).to(true)
      end
    end
  end
end

