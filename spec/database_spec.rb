require 'spec_helper'
require 'bundler/audit/database'
require 'tmpdir'

describe Bundler::Audit::Database do
  let(:vendored_advisories) do
    Dir[File.join(Bundler::Audit::Database::VENDORED_PATH, 'gems/*/*.yml')].sort
  end

  describe "path" do
    subject { described_class.path }

    it "must default to DEFAULT_PATH" do
      expect(subject.path).to be == described_class::DEFAULT_PATH
    end
  end

  describe "update!" do
    it "should create the DEFAULT_PATH path as needed" do
      Bundler::Audit::Database.update!(quiet: false)
      expect(File.directory?(mocked_user_path)).to be true
    end

    it "should create the repo, then update it given multple successive calls." do
      expect_update_to_clone_repo!
      Bundler::Audit::Database.update!(quiet: false)
      expect(File.directory?(mocked_user_path)).to be true

      expect_update_to_update_repo!
      Bundler::Audit::Database.update!(quiet: false)
      expect(File.directory?(mocked_user_path)).to be true
    end
  end

  describe "#initialize" do
    context "when given no arguments" do
      subject { described_class.new }

      it "should default path to path" do
        expect(subject.path).to eq(described_class.path)
      end
    end

    context "when given a directory" do
      let(:path ) { Dir.tmpdir }

      subject { described_class.new(path) }

      it "should set #path" do
        expect(subject.path).to eq(path)
      end
    end

    context "when given an invalid directory" do
      it "should raise an ArgumentError" do
        expect {
          described_class.new('/foo/bar/baz')
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#check_gem" do
    let(:gem) do
      Gem::Specification.new do |s|
        s.name    = 'actionpack'
        s.version = '3.1.9'
      end
    end

    context "when given a block" do
      it "should yield every advisory effecting the gem" do
        advisories = []

        subject.check_gem(gem) do |advisory|
          advisories << advisory
        end

        expect(advisories).not_to be_empty
        expect(advisories.all? { |advisory|
          advisory.kind_of?(Bundler::Audit::Advisory)
        }).to be_truthy
      end
    end

    context "when given no block" do
      it "should return an Enumerator" do
        expect(subject.check_gem(gem)).to be_kind_of(Enumerable)
      end
    end
  end

  describe "#size" do
    it { expect(subject.size).to eq vendored_advisories.count }
  end

  describe "#advisories" do
    it "should return a list of all advisories." do
      actual_advisories = Bundler::Audit::Database.new.
        advisories.
        map(&:path).
        sort

      expect(actual_advisories).to eq vendored_advisories
    end
  end

  describe "#to_s" do
    it "should return the Database path" do
      expect(subject.to_s).to eq(subject.path)
    end
  end

  describe "#inspect" do
    it "should produce a Ruby-ish instance descriptor" do
      expect(Bundler::Audit::Database.new.inspect).to eq("#<Bundler::Audit::Database:#{Bundler::Audit::Database::VENDORED_PATH}>")
    end
  end
end
