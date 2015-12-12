require_relative '../spec_helper'

describe Wpxf::Module do
  let(:subject) { Wpxf::Module.new }

  describe '#new' do
    it 'initializes the options attribute to an empty array' do
      expect(subject.options).to be_empty
    end

    it 'initializes the datastore attribute to an empty hash' do
      expect(subject.datastore).to be_empty
    end
  end

  describe '#unregister_option' do
    it 'removes an option from the options array' do
      opt = Wpxf::StringOption.new(name: 'test', desc: 'test')
      subject.register_option(opt)
      expect(subject.options).to include opt
      subject.unregister_option(opt)
      expect(subject.options).to_not include opt
    end

    it 'leaves the array unaltered if the option doesn\'t exist' do
      opt = Wpxf::StringOption.new(name: 'test', desc: 'test')
      opt2 = Wpxf::StringOption.new(name: 'test2', desc: 'test')

      subject.register_option(opt)
      expect(subject.options).to include opt
      orignal_options = subject.options

      subject.unregister_option(opt2)
      expect(subject.options).to eq orignal_options
    end
  end

  describe '#register_option' do
    it 'adds an option to the options array' do
      opt = Wpxf::StringOption.new(name: 'test', desc: 'test')
      subject.register_option(opt)
      expect(subject.options).to include opt
    end

    it 'overwrites options with the same name, rather than duplicating them' do
      opt = Wpxf::StringOption.new(name: 'test', desc: 'test')

      subject.register_option(opt)
      expect(subject.options).to include opt

      subject.register_option(opt)
      expect(subject.options.length).to eq 1
    end

    it 'adds the default value to the datastore, if one is present' do
      opt = Wpxf::StringOption.new(name: 'test', desc: 'test', default: 'def')
      subject.register_option(opt)
      expect(subject.datastore['test']).to eq 'def'
    end
  end

  describe '#register_options' do
    it 'registers each option in the array' do
      subject.register_options([
        Wpxf::Option.new(name: 'opt1', desc: 'opt1'),
        Wpxf::Option.new(name: 'opt2', desc: 'opt2'),
        Wpxf::Option.new(name: 'opt3', desc: 'opt3')
      ])

      expect(subject.options.any? { |o| o.name.eql? 'opt1' }).to be true
      expect(subject.options.any? { |o| o.name.eql? 'opt2' }).to be true
      expect(subject.options.any? { |o| o.name.eql? 'opt3' }).to be true
    end
  end

  describe '#register_advanced_options' do
    it 'sets advanced on each option to true and registers it' do
      subject.register_advanced_options([
        Wpxf::Option.new(name: 'opt1', desc: 'opt1'),
        Wpxf::Option.new(name: 'opt2', desc: 'opt2'),
        Wpxf::Option.new(name: 'opt3', desc: 'opt3')
      ])

      expect(subject.options.any? { |o| o.name.eql? 'opt1' }).to be true
      expect(subject.options.any? { |o| o.name.eql? 'opt2' }).to be true
      expect(subject.options.any? { |o| o.name.eql? 'opt3' }).to be true

      subject.options.each do |o|
        expect(o.advanced?).to be true
      end
    end
  end

  describe '#register_evasion_options' do
    it 'sets evasion on each option to true and registers it' do
      subject.register_evasion_options([
        Wpxf::Option.new(name: 'opt1', desc: 'opt1'),
        Wpxf::Option.new(name: 'opt2', desc: 'opt2'),
        Wpxf::Option.new(name: 'opt3', desc: 'opt3')
      ])

      expect(subject.options.any? { |o| o.name.eql? 'opt1' }).to be true
      expect(subject.options.any? { |o| o.name.eql? 'opt2' }).to be true
      expect(subject.options.any? { |o| o.name.eql? 'opt3' }).to be true

      subject.options.each do |o|
        expect(o.evasion?).to be true
      end
    end
  end

  describe '#get_option' do
    it 'returns the matching option' do
      subject.register_evasion_options([
        Wpxf::Option.new(name: 'opt1', desc: 'opt1'),
        Wpxf::Option.new(name: 'opt2', desc: 'opt2'),
        Wpxf::Option.new(name: 'opt3', desc: 'opt3')
      ])

      expect(subject.get_option('opt2').name).to eq 'opt2'
    end

    it 'returns nil if no option can be found' do
      expect(subject.get_option('opt2')).to be_nil
    end
  end

  describe '#set_option_value' do
    it 'returns :not_found an invalid option is specified' do
      expect(subject.set_option_value('opt1', 'val')).to eq :not_found
    end

    it 'returns :invalid if the value isn\'t valid' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      expect(subject.set_option_value('opt1', 'invalid')).to eq :invalid
    end

    it 'returns the normalized value if the value was set' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      expect(subject.set_option_value('opt1', 't')).to eq true
    end

    it 'sets the value in datastore to the value specified' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      expect(subject.set_option_value('opt1', 't')).to eq true
      expect(subject.datastore['opt1']).to eq 't'
    end
  end

  describe '#get_option_value' do
    it 'returns the value from the datastore for the specified key' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      subject.set_option_value('opt1', 't')
      expect(subject.get_option_value('opt1')).to eq 't'
    end
  end

  describe '#normalized_option_value' do
    it 'returns a normalized value from the datastore for the specified key' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      subject.set_option_value('opt1', 't')
      expect(subject.normalized_option_value('opt1')).to eq true
    end
  end

  describe '#option_value?' do
    it 'returns true if the option has a non-nil and non-empty value' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      subject.set_option_value('opt1', 't')
      expect(subject.option_value?('opt1')).to eq true
    end

    it 'returns false if the option value hasn\'t been set' do
      opt = Wpxf::BooleanOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      expect(subject.option_value?('opt1')).to eq false
    end

    it 'returns false if the option value is empty' do
      opt = Wpxf::StringOption.new(name: 'opt1', desc: 'opt1')
      subject.register_option(opt)
      subject.set_option_value('opt1', '')
      expect(subject.option_value?('opt1')).to eq false
    end
  end

  describe '#scoped_option_change' do
    it 'yields a block with the option changed to the new value' do
      opt = Wpxf::StringOption.new(name: 'key', desc: 'key')
      subject.register_option(opt)
      subject.scoped_option_change('key', 'newval') do |val|
        expect(subject.get_option_value('key')).to eq 'newval'
        expect(val).to eq 'newval'
      end
    end

    it 'resets the value to its original value after invoking the block' do
      opt = Wpxf::StringOption.new(name: 'key', desc: 'key')
      subject.register_option(opt)
      subject.set_option_value('key', 'original')
      subject.scoped_option_change('key', 'newval') do |val|
        expect(subject.get_option_value('key')).to eq 'newval'
        expect(val).to eq 'newval'
      end
      expect(subject.get_option_value('key')).to eq 'original'
    end
  end
end
