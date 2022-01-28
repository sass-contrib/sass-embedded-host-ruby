# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sass do
  it 'emits debug to stderr by default' do
    stdio = capture_stdio do
      described_class.compile_string('@debug heck')
    end
    expect(stdio.out).to be_empty
    expect(stdio.err).not_to be_empty
  end

  describe 'with @warn' do
    it 'passes the message and stack trace to the logger' do
      described_class.compile_string('
                                     @mixin foo {@warn heck}
                                     @include foo;
                                     ', logger: {
                                       warn: lambda { |message, deprecation:, span:, stack:|
                                         expect(message).to eq('heck')
                                         expect(span).to be_nil
                                         expect(stack).to be_a(String)
                                         expect(deprecation).to be(false)
                                       }
                                     })
    end

    it 'stringifies the argument' do
      described_class.compile_string('@warn #abc',
                                     logger: {
                                       warn: lambda { |message, **_kwargs|
                                         expect(message).to eq('#abc')
                                       }
                                     })
    end

    it "doesn't inspect the argument" do
      described_class.compile_string('@warn null',
                                     logger: {
                                       warn: lambda { |message, **_kwargs|
                                         expect(message).to eq('')
                                       }
                                     })
    end

    it 'emits to stderr by default' do
      stdio = capture_stdio do
        described_class.compile_string('@warn heck')
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).not_to be_empty
    end

    it "doesn't emit warnings with a warn callback" do
      stdio = capture_stdio do
        described_class.compile_string('@warn heck',
                                       logger: {
                                         warn: ->(_message, **_kwargs) {}
                                       })
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).to be_empty
    end

    it 'still emits warning with only a debug callback' do
      stdio = capture_stdio do
        described_class.compile_string('@warn heck',
                                       logger: {
                                         debug: ->(_message, **_kwargs) {}
                                       })
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).not_to be_empty
    end

    it "doesn't emit warnings with Logger.silent" do
      stdio = capture_stdio do
        described_class.compile_string('@warn heck',
                                       logger: Sass::Logger.silent)
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).to be_empty
    end
  end

  describe 'with @debug' do
    it 'passes the message and span to the logger' do
      described_class.compile_string('@debug heck',
                                     logger: {
                                       debug: lambda { |message, span:, **_kwargs|
                                         expect(message).to eq('heck')
                                         expect(span.start.line).to eq(0)
                                         expect(span.start.column).to eq(0)
                                         expect(span.end.line).to eq(0)
                                         expect(span.end.column).to eq(11)
                                       }
                                     })
    end

    it 'stringifies the argument' do
      described_class.compile_string('@debug #abc',
                                     logger: {
                                       debug: lambda { |message, **_kwargs|
                                         expect(message).to eq('#abc')
                                       }
                                     })
    end

    it 'inspects the argument' do
      described_class.compile_string('@debug null',
                                     logger: {
                                       debug: lambda { |message, **_kwargs|
                                         expect(message).to eq('null')
                                       }
                                     })
    end

    it 'emits to stderr by default' do
      stdio = capture_stdio do
        described_class.compile_string('@debug heck')
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).not_to be_empty
    end

    it "doesn't emit debugs with a debug callback" do
      stdio = capture_stdio do
        described_class.compile_string('@debug heck',
                                       logger: {
                                         debug: ->(_message, **_kwargs) {}
                                       })
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).to be_empty
    end

    it 'still emits debugs with only a warn callback' do
      stdio = capture_stdio do
        described_class.compile_string('@debug heck',
                                       logger: {
                                         warn: ->(_message, **_kwargs) {}
                                       })
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).not_to be_empty
    end

    it "doesn't emit debugs with Logger.silent" do
      stdio = capture_stdio do
        described_class.compile_string('@debug heck',
                                       logger: Sass::Logger.silent)
      end
      expect(stdio.out).to be_empty
      expect(stdio.err).to be_empty
    end
  end

  describe 'compile' do
    it 'emits to stderr by default' do
      sandbox do |dir|
        dir.write({ 'style.scss' => '@warn heck; @debug heck' })
        stdio = capture_stdio do
          described_class.compile(dir.path('style.scss'))
        end
        expect(stdio.out).to be_empty
        expect(stdio.err).not_to be_empty
      end
    end

    it "doesn't emit to stderr with callbacks" do
      sandbox do |dir|
        dir.write({ 'style.scss' => '@warn heck warn; @debug heck debug' })
        stdio = capture_stdio do
          described_class.compile(dir.path('style.scss'),
                                  logger: {
                                    warn: lambda { |message, **_kwargs|
                                      expect(message).to eq('heck warn')
                                    },
                                    debug: lambda { |message, **_kwargs|
                                      expect(message).to eq('heck debug')
                                    }
                                  })
        end
        expect(stdio.out).to be_empty
        expect(stdio.err).to be_empty
      end
    end
  end
end
