#! /usr/bin/env ruby
## -*- Mode: ruby -*-
##Header:
##Title: Uniform Random Value Class
##Author: Itsuki Noda
##Date: 2006/06/21
##EndHeader:

require 'Stat/RandomValue.rb' ;
##======================================================================
module Stat
  class Uniform < RandomValue 
    attr :min, true ;
    attr :max, true ;
    attr :mode, true ;	# should be :uniform, :log

    ##------------------------------
    def initialize(minValue, maxValue, mode = :uniform)
      @min = minValue ;
      @max = maxValue ;
      @mode = mode ;
    end

    ##------------------------------
    def value()
      case(@mode)
      when :uniform
        (@max - @min) * rand() + @min ;
      when :log
        Math::exp((@max - @min) * rand() + @min) ;
      end
    end

    ##------------------------------
    def to_s()
      "#<Stat::Uniform:[#{@min}:#{@max}]/#{@mode}>" ;
    end


  end

end
