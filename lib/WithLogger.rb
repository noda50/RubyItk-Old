##  -*- Mode: ruby -*-

$LOAD_PATH.push('~/lib/ruby') if(!$LOAD_PATH.member?('~/lib/ruby')) ;
require 'WithConfParam.rb' ;

##======================================================================
module Itk

  ##============================================================
  module LogUtility
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    Level = {
      :none => LevelNone = 0,
      :info => LevelInfo = 1,
      :debug => LevelDebug = 2,
      :error => LevelError = 3,
      :fatal => LevelFatal = 4,
      :top => LevelTop = 5,
    } ;
    LevelName = {} ;
    Level.each{|key, value| LevelName[value] = key.to_s.capitalize} ;

    ##--------------------------------------------------
    def loggingTo(strm, obj, newlinep = true)
      if(obj.is_a?(Array))
        loggingTo_Array(strm, obj) ;
      elsif(obj.is_a?(Hash))
        loggingTo_Hash(strm, obj) ;
      elsif(obj.is_a?(Time))
        loggingTo_Time(strm, obj) ;
      elsif(obj.is_a?(Numeric))
        loggingTo_Atom(strm, obj) ;
      elsif(obj.is_a?(String))
        loggingTo_Atom(strm, obj) ;
      elsif(obj.is_a?(Symbol))
        loggingTo_Atom(strm, obj) ;
      elsif(obj.is_a?(Class))
        loggingTo_Atom(strm, obj) ;
      elsif(obj == true || obj == false || obj == nil)
        loggingTo_Atom(strm, obj) ;
      else
        loggingTo_Object(strm, obj) ;
      end
      strm << "\n" if(newlinep) ;
    end

    ##--------------------------------------------------
    def loggingTo_Array(strm, obj)
      strm << '[' ;
      initp = true ;
      obj.each{|value| 
        strm << ', ' if(!initp) ;
        initp = false ;
        loggingTo(strm, value, false) ;
      }
      strm << ']' ;
    end

    ##--------------------------------------------------
    def loggingTo_Hash(strm, obj)
      strm << '{' ;
      initp = true ;
      obj.each{|key,value| 
        strm << ', ' if(!initp) ;
        initp = false ;
        loggingTo(strm, key, false) ;
        strm << '=>'
        loggingTo(strm, value, false) ;
      }
      strm << '}' ;
    end

    ##--------------------------------------------------
    def loggingTo_Time(strm, obj)
      strm << 'Time::local(*' ;
      strm << obj.to_a.inspect ;
      strm << ')' ;
    end

    ##--------------------------------------------------
    def loggingTo_Object(strm, obj)
      strm << '{' ;
      strm << ':__class__' << '=>' << obj.class.inspect ;
      obj.instance_variables.each{|var|
        strm << ', ' ;
        strm << (var.slice(1...var.size).intern.inspect) ;
        strm << '=>'
        loggingTo(strm, obj.instance_eval("#{var}"), false) ;
      }
      strm << '}' ;
    end

    ##--------------------------------------------------
    def loggingTo_Atom(strm, obj)
      strm << obj.inspect ;
    end

  end ## module Itk::LogUtility

  module LogUtility ; extend LogUtility ; end

  ##============================================================
  class Logger < WithConfParam
    include LogUtility
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    DefaultConf = {
      :stream => $stdout,
      :file => nil,
      :append => false,
      :level => LevelNone,
      :withLevel => false,
    } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :stream, true ;
    attr :file, true ;
    attr :level, true ;
    attr :withLevelp, true ;

    ##--------------------------------------------------
    def initialize(conf = {})
      super(conf) ;
      setup() ;
    end

    ##--------------------------------------------------
    def setup()
      @append = getConf(:append) ;
      @file = getConf(:file) ;
      if(@file)
        @stream = openFile(@file) ;
      end
      @stream = @stream || getConf(:stream) ;
      @level = getConf(:level) ;
      @withLevel = getConf(:withLevel) ;
      @stream ;
    end

    ##--------------------------------------------------
    def openFile(file, mode=nil) # mode = nil | 'w' | 'a' | 'r'
      if(mode.nil?)
        mode = @appendp ? 'a' : 'w' ;
      end

      @file = file ;
      @stream = open(@file, mode) ;
    end

    ##--------------------------------------------------
    def setLevel(level)
      @level = level ;
    end

    ##--------------------------------------------------
    def setWithLevel(flag = true)
      @withLevel = flag ;
    end

    ##--------------------------------------------------
    def put(level,message)
      if(level >= @level)
        @stream << LevelName[level] << ": " if(@withLevel) ;
        loggingTo(@stream,message) ;
      end
    end

    ##--------------------------------------------------
    def <<(message)
      put(LevelTop,message) ;
    end

    ##--------------------------------------------------
    def info(message)
      put(LevelInfo, message) ;
    end

    ##--------------------------------------------------
    def debug(message)
      put(LevelDebug, message) ;
    end

    ##--------------------------------------------------
    def error(message)
      put(LevelError, message) ;
    end

    ##--------------------------------------------------
    def fatal(message)
      put(LevelFatal, message) ;
    end

    ##--------------------------------------------------
    def close()
      if(@file)
        @stream.close() ;
      end
    end

  end # class Logger

  ##============================================================
  class << Logger
    extend LogUtility ;

    Entity = Logger.new() ;
    ##--------------------------------------------------
    def logger()
      Entity ;
    end

    ##--------------------------------------------------
    def openFile(file, mode = nil)
      logger().openFile(file,mode) ;
    end

    ##--------------------------------------------------
    def setLevel(level)
      logger().setLevel(level) ;
    end
    ##--------------------------------------------------
    def setWithLevel(flag=true)
      logger().setWithLevel(flag) ;
    end

    ##--------------------------------------------------
    def put(level, message)
      logger().put(level, message) ;
    end

    ##--------------------------------------------------
    def <<(message)
      logger() << message ;
    end

    ##--------------------------------------------------
    def info(message)
      logger().info(message) ;
    end

    ##--------------------------------------------------
    def debug(message)
      logger().debug(message) ;
    end

    ##--------------------------------------------------
    def error(message)
      logger().error(message) ;
    end

    ##--------------------------------------------------
    def fatal(message)
      logger().fatal(message) ;
    end

    ##--------------------------------------------------
    def close()
      logger().close() ;
    end

    ##--------------------------------------------------
    def withLogger(conf = {}, &block)
      _logger = Logger.new(conf) ;
      begin
        block.call(_logger) ;
      ensure
        _logger.close() ;
      end
    end

  end # class << Logger


end ## module Itk

######################################################################
######################################################################
######################################################################
if($0 == __FILE__) then
  require 'test/unit'

  ##============================================================
  class TC_WithLogger < Test::Unit::TestCase

    ##----------------------------------------
    def setup
      puts ('*' * 5 ) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    ##----------------------------------------
    def test_a()
      data = [:foo,
              [true, false, nil, :foo, Array],
              [1, 2.0, -3.4, 0x3],
              Time.now,
              {:a => [1,2,3], :c => Hash, :d => {1 => 2, "bar" => 'baz'}},
              Foo.new()] ;
      Itk::LogUtility::loggingTo($stdout , data) ;
      str = "" ;
      Itk::LogUtility::loggingTo(str, data) ;
      p str ;
      d = eval(str) ;
      p [:eval, d] ;
      Itk::LogUtility::loggingTo($stdout, d) ;
    end

    class Foo
      def initialize()
        @bar = "" ;
        @baz = :abcde ;
        @foo = [1,2,3,4,5] ;
      end
    end

    ##----------------------------------------
    def test_b()
      test_b_sub() ;
      Itk::Logger.setWithLevel() ;
      test_b_sub() ;
    end
    ##----------------------------------------
    def test_b_sub()
      Itk::Logger << "foo" ;
      Itk::Logger << [:a, "b", Foo.new(), {:a => 1, 2 => 3.1415, "3" => [1,2,3]}] ;
      [Itk::Logger::LevelInfo, Itk::Logger::LevelDebug,
       Itk::Logger::LevelError, Itk::Logger::LevelFatal].each{|lv|
        Itk::Logger.setLevel(lv) ;
        Itk::Logger.info([:info, [:level, lv]]) ;
        Itk::Logger.debug([:info, [:level, lv]]) ;
        Itk::Logger.error([:info, [:level, lv]]) ;
        Itk::Logger.fatal([:info, [:level, lv]]) ;
      } ;
    end

  end ##   class TC_WithLogger

end
