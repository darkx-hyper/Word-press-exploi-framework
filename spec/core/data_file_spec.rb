require_relative '../spec_helper'

describe Wpxf::DataFile do
  let(:subject) { Wpxf::DataFile.new('php', 'exec.php') }

  describe '#new' do
    it 'opens the specified file and reads its contents into the #contents attribute' do
      expect(subject.content).to match(/echo \$wpxf_exec\(base64_decode\(\$cmd\)\);/)
    end
  end

  describe '#php_content' do
    it 'returns the file contents with <php and ?> trimmed from the start and end of the string' do
      expect(subject.php_content).to_not match(/^<\?php.*\?>^/)
    end
  end
end
