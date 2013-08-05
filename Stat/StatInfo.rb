#! /usr/bin/env ruby
## -*- mode: ruby -*-

module Stat

  ##======================================================================
=begin
== StatInfo

   * Cumulate statical infomation and calculate average, variance and
     standard diviation. 
   
   * It also record history.

=end

  class StatInfo
    attr :min, true ;
    attr :max, true ;

    attr :sum, true ;
    attr :qsum, true ;
    attr :countN, true ;

    attr :history, true ;
    attr :historySize, true ;

    ##--------------------------------------------------
    def initialize(historySize = 1)
      # historySize = 0 means infinite history

      @sum = 0.0 ;
      @qsum = 0.0 ;
      @countN = 0 ;

      @min = nil ;
      @max = nil ;

      @historySize = historySize ;
      @history = Array.new(@historySize) ;
    end

    ##--------------------------------------------------
    def put(value)
      @min = value if (@min.nil? || value < @min) ;
      @max = value if (@max.nil? || value > @max) ;

      @sum += value ;
      @qsum += value * value ;

      if(@historySize > 0)
        @history[@countN % @history.size] = value ;
      else
        @history.push(value) ;
      end

      @countN += 1 ;
    end

    ##--------------------------------------------------
    ## access to history

    ##--------------------
    def last(n = 1)
      return @history[-n] ;
    end

    ##--------------------
    def nth(n)
      return @history[n] ;
    end

    ##--------------------------------------------------
    ## calc stat info

    ##--------------------
    def average()
      if(@countN > 0) then
        return @sum / @countN ;
      else
        return 0.0 ;
      end
    end

    alias ave average ;

    ##--------------------
    def variance()
      if(@countN > 0 && @min < @max) then
        ave = average() ;
        return @qsum / @countN - ave * ave ;
      else
        return 0.0 ;
      end
    end

    alias var variance ;

    ##--------------------
    def sdiv()
      return Math::sqrt(variance()) ;
    end

    alias sdev sdiv ;  
    alias std sdiv ;

  end

  ##======================================================================
=begin
== Correlation2

   * cumulate correlation information of two variables

=end

  class Correlation2
    attr :xStat, true ;
    attr :yStat, true ;
    attr :xyStat, true ;

    ##--------------------
    def initialize()
      @xStat = StatInfo.new()
      @yStat = StatInfo.new() ;
      @xyStat = StatInfo.new() ;
    end

    ##--------------------
    def put(xVal, yVal)
      @xStat.put(xVal) ;
      @yStat.put(yVal) ;
      @xyStat.put(xVal * yVal) ;
    end

    ##--------------------
    def covariance()
      return @xyStat.average() - @xStat.average() * @yStat.average() ;
    end

    ##--------------------
    def correlation()
      return covariance() / (@xStat.sdiv() * @yStat.sdiv()) ;
    end

  end
    
  ##======================================================================
=begin
== TwoArrayStatInfo

   * cumulate correlation information of two arrays

=end

  class TwoArrayStatInfo
    attr :sizeX, true ;
    attr :sizeY, true ;
    attr :statInfoX, true ;
    attr :statInfoY, true ;
    attr :qMatrix, true ;
    attr :count, true ;

    attr :averageX, true ;
    attr :averageY, true ;
    attr :covariance, true ;

    ##--------------------
    def initialize(sizeY, sizeX, historySize = 1)
      setup(sizeY, sizeX, historySize) ;
    end

    ##--------------------
    def setup(sizeY, sizeX, historySize) ;
      @sizeX = sizeX ;
      @sizeY = sizeY ;
      @historySize = historySize ;

      @statInfoX = Array.new(@sizeX){ StatInfo.new(historySize) ; }
      @statInfoY = Array.new(@sizeY){ StatInfo.new(historySize) ; }
      @qMatrix = Array.new(@sizeY){ Array.new(@sizeX,0.0) ; } ;
      @count = 0 ;
    end

    ##--------------------
    def put(valueY, valueX)
      (0...@sizeY).each{|i|
        @statInfoY[i].put(valueY[i]) ;
        (0...@sizeX).each{|j|
          @statInfoX[j].put(valueX[j]) if(i == 0) ;
          @qMatrix[i][j] += valueY[i] * valueX[j] ;
        }
      }
      @averageX = nil ;
      @averageY = nil ;
      @covariance = nil ;
      @count += 1 ;
    end

    ##--------------------
    def averageX()
      if(@averageX.nil?) then
        @averageX = Array.new(@sizeX) ;
        (0...@sizeX).each{|i|
          @averageX[i] = @statInfoX[i].average() ;
        }
      end
      return @averageX ;
    end
    ##--------------------
    def averageY()
      if(@averageY.nil?) then
        @averageY = Array.new(@sizeY) ;
        (0...@sizeY).each{|i|
          @averageY[i] = @statInfoY[i].average() ;
        }
      end
      return @averageY ;
    end

    ##--------------------
    def covariance() 
      if(@covariance.nil?) then
        aveX = averageX() ;
        aveY = averageY() ;
        @covariance = Array.new(@sizeY){ Array.new(@sizeX,0.0) }  ;
        (0...@sizeY).each{|i|
          (0...@sizeX).each{|j|
            @covariance[i][j] = @qMatrix[i][j]/@count.to_f - aveY[i] * aveX[j] ;
          }
        }
      end
      return @covariance ;
    end

  end
    

  ##======================================================================
=begin
== ArrayStatInfo

   * cumulate correlation information of two variables

=end

  class ArrayStatInfo < TwoArrayStatInfo
    ##--------------------
    def initialize(size, historySize = 1)
      setup(size, size, historySize) ;
    end

    ##--------------------
    def put(value)
      super(value, value) ;
    end

    ##--------------------
    def averageY()
      averageX() ;
      @averageY = @averageX ;
    end

    ##--------------------
    def average()
      averageX() ;
    end


  end
  ##======================================================================
=begin
== ArrayStatInfo_old

   * cumulate correlation information of two variables

=end

  class ArrayStatInfo_old
    attr :size, true ;
    attr :statInfo, true ;
    attr :qMatrix, true ;
    attr :count, true ;

    attr :average, true ;
    attr :covariance, true ;

    ##--------------------
    def initialize(size, historySize = 1)
      setup(size, historySize) ;
    end

    ##--------------------
    def setup(size, historySize) ;
      @size = size ;
      @historySize = historySize ;

      @statInfo = Array.new(@size){ StatInfo.new(historySize) ; }
      @qMatrix = Array.new(@size){ Array.new(@size,0.0) ; } ;
      @count = 0 ;
    end

    ##--------------------
    def put(value)
      (0...@size).each{|i|
        @statInfo[i].put(value[i]) ;
        (0...@size).each{|j|
          @qMatrix[i][j] += value[i] * value[j] ;
        }
      }
      @count += 1 ;
      @average = nil ;
      @covariance = nil ;
    end

    ##--------------------
    def average()
      if(@average.nil?) then
        @average = Array.new(@size) ;
        (0...@size).each{|i|
          @average[i] = @statInfo[i].average() ;
        }
      end
      return @average ;
    end

    ##--------------------
    def covariance() 
      if(@covariance.nil?) then
        ave = average() ;
        @covariance = Array.new(@size){ Array.new(@size,0.0) }  ;
        (0...@size).each{|i|
          (0...@size).each{|j|
            @covariance[i][j] = @qMatrix[i][j]/@count.to_f - ave[i] * ave[j] ;
          }
        }
      end
      return @covariance ;
    end

  end


end
