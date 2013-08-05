#! /usr/bin/env ruby
## -*- Mode: ruby -*-

$LOAD_PATH.push("~/lib/ruby") ;
require 'sexp.rb' ;

## WithConfParam library

##======================================================================
class WithConfParam

  ##::::::::::::::::::::::::::::::::::::::::::::::::::
  DefaultConf = { nil => nil } ;
  DefaultValue = nil ;
  
  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  attr :conf, true ;
  
  ##--------------------------------------------------
  def initialize(conf = {}) 
    setPiledConf(conf) ;
  end

  ##--------------------------------------------------
  def setPiledConf(conf) 
    @conf = genPiledConf(conf) ;
  end

  ##--------------------------------------------------
  def genPiledConf(conf = {})
    return genPiledDefaultConf().update(conf) ;
  end

  ##--------------------------------------------------
  def genPiledDefaultConf(klass = self.class())
    if(klass == WithConfParam) then
      return klass::DefaultConf.dup() ;
    else
      newConf = genPiledDefaultConf(klass.superclass()) ;
      if(klass.const_defined?(:DefaultConf)) 
        newConf.update(klass::DefaultConf) ;
      end
      
      return newConf ;
    end
  end
      
  ##--------------------------------------------------
  def setConf(key, value)
    @conf[key] = value ;
  end

  ##--------------------------------------------------
  def getConf(key, defaultValue = DefaultValue, conf = @conf)
    if (conf.key?(key)) then
      return conf[key] ;
    elsif(conf != @conf && @conf.key?(key)) then
      return @conf[key] ;
    else
      return defaultValue ;
    end
  end

  ##--------------------------------------------------
  def to_SexpConf()
    return to_SexpConfBody(:conf, @conf) ;
  end

  ##--------------------------------------------------
  def to_SexpConfBody(tag, conf)
    body = Sexp::nil ;
    atomP = false ;
    if(conf.is_a?(Hash)) then
      conf.each{|key,value|
        next if (key.nil? && value.nil?) ;
        entry = to_SexpConfBody(key,value) ;
        body = Sexp::cons(entry, body) ;
      }
      body = body.reverse() ;
    elsif(conf.is_a?(Array)) then
      conf.each{|value|
        entry = to_SexpConfBody(nil, value) ;
        body = Sexp::cons(entry, body) ;
      }
      body = body.reverse() ;
    else
      body = Sexp::list(conf) ;
      atomP = true ;
    end

    if(tag.nil?) then
      body = body.car() if(atomP) ;
      sexp = body ;
    else
      sexp = Sexp::cons(tag, body) ;
    end
    
    return sexp ;
  end

end ## class WithConfParam


########################################################################
########################################################################
## for test
########################################################################
########################################################################
if($0 == __FILE__) then

  class Foo < WithConfParam
    DefaultConf = { :x => 1 } ;
  end

  class Bar < Foo
    DefaultConf = { :y => 2 } ;
  end

  class Coo < Bar
    DefaultConf = { :x => 3 } ;
  end

  f0 = Foo.new() ;
  b0 = Bar.new() ;
  c0 = Coo.new() ;
  c1 = Coo.new({:y => 4}) ;
  
    

  p [:f0, :x, f0.getConf(:x)] ;
  p [:f0, :y, f0.getConf(:y)] ;
  p [:b0, :x, b0.getConf(:x)] ;
  p [:b0, :y, b0.getConf(:y)] ;
  p [:c0, :x, c0.getConf(:x)] ;
  p [:c0, :y, c0.getConf(:y)] ;
  p [:c1, :x, c1.getConf(:x)] ;
  p [:c1, :y, c1.getConf(:y)] ;

end
