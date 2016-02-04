require 'spec_helper'
describe 'howalarming' do

  context 'with defaults for all parameters' do
    it { should contain_class('howalarming') }
  end
end
