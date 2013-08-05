## -*- Mode: ruby -*-

######################################################################
=begin 
= TimeDuration Library

== Usage
        td = TimeDuration.new() ;    ## 0 sec duration
        td = TimeDuration.new(2.5) ; ## 2.5 sec duration
        td = TimeDuration.new(t1,t2) ; ## duration between t1 and t2
        td = TimeDuration.new(){ sleep(10) } ; ## duration to exec a block
        td += 3.1 ; ## add 3.1 sec to self.
        td2 = td + 2.7 ;  ## new duration of sum of td and 2.7 sec.
        td2 += td ; ## td2 is incremented by a duration ((|td|))
== class TimeDuration
=end
######################################################################

##====================================================================
=begin
--- class Tim
    * add isoStr method.
=end
##====================================================================
class Time
  IsoTimeFormatFull = "%Y-%m-%dT%H:%M:%S%z" ;

  def isoStr(type = :full)
    case type
    when :full
      return self.strftime(IsoTimeFormatFull) ;
    else
      raise "Unknown ISO time format type:" + type.to_s ;
    end
  end
end

=begin

--- class TimeDuration
     * class to store a duration of time.
     * instance variables:
       * (({ @sec })) : duration in time.
       * (({ @beginTime })) : beginning time to measure duration.
       * (({ @endTime })) : ending time to measure duration.
=end
##====================================================================
class TimeDuration
  attr :sec, true ;
  attr :beginTime, true ;
  attr :endTime, true ;

##--------------------------------------------------------------------
=begin
--- initialize(bTime = nil, eTime = nil, &block)
     * initialize new instance.
     * four tipes of initialization
       * (({ TimeDuration.new() })) : set 0 second as initial duration.
       * (({ TimeDuration.new( ((| inSecond |)) ) })) : 
         set ((| inSecond |)) as initial duration.
         ((| inSecond |)) should be a Number.
       * (({ TimeDuration.new( ((| beginTime |)), ((| endTime |)) )})) :
         set difference of ((| beginTime |)) and ((| endTime |)).
         ((| beginTime |)) and ((| endTime |)) should be Times.
       * (({ TimeDuration.new(){ ((| operations |)) } })) :
         set execution time of ((| operations |)).
=end  
##--------------------------------------------------------------------
  def initialize(bTime = nil, eTime = nil, &block)
    if (!block.nil?) then
      if(bTime.nil? && eTime.nil?) then
        setProcessingTime(&block) ;
      else
        raise "Illegal call format for initialize."
      end
    elsif (!bTime.nil?)
      if(!eTime.nil?)
        if(bTime.is_a?(Time) && eTime.is_a?(Time)) then
          setBeginEndTime(bTime, eTime) ;
        else
          raise "Illegal call format for initialize."
        end
      else
        if(bTime.is_a?(Numeric)) then
          setSec(bTime) ;
        else
          raise "Illegal call format for initialize."
        end
      end
    else
      if(eTime.nil?) then
        setSec(0.0) ;
      else
        raise "Illegal call format for initialize."
      end
    end
  end

##--------------------------------------------------------------------
=begin
--- setSec(sec)
     * set duration in seconds
=end  
##--------------------------------------------------------------------
  def setSec(sec)
    @sec = sec.to_f ;
  end

##--------------------------------------------------------------------
=begin
--- setTime(hour,min,sec)
     * set duration in hour, min, and second
=end  
##--------------------------------------------------------------------
  def setTime(hour, min, sec)
    setSec(sec) ;
    addMin(min) ;
    addHour(hour) ;
  end

##--------------------------------------------------------------------
=begin
--- setTime(hour,min,sec)
     * set duration in hour, min, and second
=end  
##--------------------------------------------------------------------
  def addTime(hour, min, sec)
    addSec(sec) ;
    addMin(min) ;
    addHour(hour) ;
  end

##--------------------------------------------------------------------
=begin
--- setBeginEndTime(bTime, eTime)
     * set duration by begininig and ending times.
=end  
##--------------------------------------------------------------------
  def setBeginEndTime(bTime, eTime)
    @beginTime = bTime if(!bTime.nil?)
    @endTime = eTime if(!eTime.nil?) ;
    fixSecByBeginEndIfPossible() ;
  end

##--------------------------------------------------------------------
  def fixSecByBeginEndIfPossible(bTime = @beginTime, eTime = @endTime)
    if(bTime.is_a?(Time) and eTime.is_a?(Time))
      @sec = eTime - bTime ;
    end
  end

##--------------------------------------------------------------------
=begin
--- setProcessingTime(&block)
     * set duration to process a given block.
=end  
##--------------------------------------------------------------------
  def setProcessingTime(&block)
    bTime = Time.new() ;
    block.call() ;
    eTime = Time.new() ;
    setBeginEndTime(bTime, eTime) ;
  end

##--------------------------------------------------------------------
=begin
--- addSec(sec)
     * add to duration in seconds
=end  
##--------------------------------------------------------------------
  def addSec(sec)
    @sec += sec ;
    return self ;
  end

##--------------------------------------------------------------------
=begin
--- addMin(min)
     * add to duration in minutes
=end  
##--------------------------------------------------------------------
  def addMin(min)
    addSec(min * 60)  ;
  end

##--------------------------------------------------------------------
=begin
--- addHour(hour)
     * add to duration in hours
=end  
##--------------------------------------------------------------------
  def addHour(hour)
    addMin(hour * 60) ;
  end
  
##--------------------------------------------------------------------
=begin
--- addUSec(usec)
     * add to duration in micro seconds
=end  
##--------------------------------------------------------------------
  def addUSec(usec)
    addSec(usec / 1000000.0) ;
  end

##--------------------------------------------------------------------
=begin
--- normalize(value, mod, unit)
     * normalize ((| value |)) in modulo of ((| mod |)) and cut-off
       by ((| unit |)).
=end  
##--------------------------------------------------------------------
  def normalize(value, mod, unit)
    value = value % mod if (mod && mod > 0) ;
    remain = 0 ;
    remain = value % unit if (unit && unit > 0) ;

    return value - remain ;
  end

##--------------------------------------------------------------------
=begin
--- getSec(mod = 60, unit = nil)
     * get duration in seconds. (normalized by ((| mod |))).
=end  
##--------------------------------------------------------------------
  def getSec(mod = 60, unit = nil)
    return normalize(@sec, mod, unit) ;
  end

##--------------------------------------------------------------------
=begin
--- getMin(mod = 60, unit = 1)
     * get duration in minutes. (normalized by ((| mod |))).
=end  
##--------------------------------------------------------------------
  def getMin(mod = 60, unit = 1)
    return normalize(getSec(0,0)/60.0, mod, unit) ;
  end

##--------------------------------------------------------------------
=begin
--- getHour(mod = 24, unit = 1)
     * get duration in hours. (normalized by ((| mod |))).
=end  
##--------------------------------------------------------------------
  def getHour(mod = 24, unit = 1)
    return normalize(getMin(0,0)/60.0, mod, unit) ;
  end

##--------------------------------------------------------------------
=begin
--- add(time)
     * return new TimeDulatin of the summation of ((|self|)) and ((|time|)).
     
=end  
##--------------------------------------------------------------------
  def add(time)
    newDuration = self.dup() ;
    return self.inc(time) ;
  end

  def +(time)
    add(time) 
  end


##--------------------------------------------------------------------
=begin
--- inc(time)
     * increment ((| time |)) and set self data.
=end  
##--------------------------------------------------------------------
  def inc(time)
    if(time.is_a?(Numeric)) then
      return self.addSec(time) ;
    elsif(time.is_a?(TimeDuration)) then
      return self.addSec(time.sec()) ;
    else
      raise "Illegal inc format(" + time.inspect() + ")"
    end
  end

##--------------------------------------------------------------------
=begin
--- mulSelf(value)
     * multiply by ((| value |)) and set self data.
=end  
##--------------------------------------------------------------------
  def mulSelf(value)
    if(time.is_a?(Numeric)) then
      @sec *= value ;
    else
      raise "Illegal mulSelf argument(" + value.inspect() + ")"
    end
    return self ;
  end

##--------------------------------------------------------------------
=begin
--- mul(value)
     * multiply by ((| value |)) and generage new TimeDuration
=end  
##--------------------------------------------------------------------
  def mul(value)
    newDuration = self.class.new(@sec) ;
    newDuration.mulSelf(value) ;
  end

##--------------------------------------------------------------------
=begin
--- *(value)
     * multiply by ((| value |)) and generage new TimeDuration
=end  
##--------------------------------------------------------------------
  def *(value)
    mul(value) ;
  end

##--------------------------------------------------------------------
=begin
--- divSelf(value)
     * divide by ((| value |)) and set self data.
=end  
##--------------------------------------------------------------------
  def divSelf(value)
    if(time.is_a?(Numeric)) then
      @sec /= value ;
    else
      raise "Illegal mulSelf argument(" + value.inspect() + ")"
    end
    return self ;
  end

##--------------------------------------------------------------------
=begin
--- div(value)
     * divide by ((| value |)) and generage new TimeDuration
=end  
##--------------------------------------------------------------------
  def div(value)
    newDuration = self.class.new(@sec) ;
    newDuration.divSelf(value) ;
  end

##--------------------------------------------------------------------
=begin
--- /(value)
     * divid by ((| value |)) and generage new TimeDuration
=end  
##--------------------------------------------------------------------
  def /(value)
    mul(value) ;
  end

##--------------------------------------------------------------------
=begin
--- endTimeFrom(bTime)
     * return end time of duration from ((| bTime |)).
=end  
##--------------------------------------------------------------------
  def endTimeFrom(bTime)
    return bTime + @sec ;
  end

##--------------------------------------------------------------------
=begin
--- endTimeFromNow()
     * return end time of duration from the current time.
=end  
##--------------------------------------------------------------------
  def endTimeFromNow() ;
    return endTimeFrom(Time.new()) ;
  end

##--------------------------------------------------------------------
=begin
--- includes(time)
     * check the duration include ((|time|))
=end  
##--------------------------------------------------------------------
  
  def includes(time)
    return (@beginTime < time && time < @endTime) ;
  end

##--------------------------------------------------------------------
=begin
--- intersects(duration)
     * check the duration intersects with ((|duration|))
=end  
##--------------------------------------------------------------------
  
  def intersects(duration)
    return (includes(duration.beginTime) || includes(duration.endTime) ||
            duration.includes(@beginTime) || duration.includes(@endTime)) ;
  end

##--------------------------------------------------------------------
=begin
--- timestr()
     * make a string of time part
=end  
##--------------------------------------------------------------------
  def timestr(subsec = true)
    if(subsec)
      "%02d:%02d:%06.3f" % [ getHour(nil).to_i,
                             getMin().to_i,
                             getSec().to_f ] ;
    else
      "%02d:%02d:%02d" % [ getHour(nil).to_i,
                             getMin().to_i,
                             getSec().to_i ] ;
    end

  end

##--------------------------------------------------------------------
=begin
--- to_i()
     * make a integer value in seconds.
=end  
##--------------------------------------------------------------------
  def to_i()
    @sec.to_i ;
  end

##--------------------------------------------------------------------
=begin
--- to_f()
     * make a float value in seconds.
=end  
##--------------------------------------------------------------------
  def to_f()
    @sec.to_f ;
  end

##--------------------------------------------------------------------
=begin
--- to_s()
     * make a string.
=end  
##--------------------------------------------------------------------
  def to_s()
    "\#<TimeDuration %s>" % timestr() ;
  end
end

######################################################################
######################################################################
######################################################################
if($0 == __FILE__) then
  ##==================================================
  class << TimeDuration

    ##----------------------------------------
    def test_initialize()
      p TimeDuration.new() ;
      p TimeDuration.new(3141.592) ;

      bTime = Time.new() ;
      sleep(1) ;
      eTime = Time.new() ;
      p [bTime, eTime] ;
      p TimeDuration.new(bTime, eTime) ;
      
      p TimeDuration.new(){ sleep(1.5) }
    end 

    ##----------------------------------------
    def test_inc()
      td = TimeDuration.new(271.8281828)
      puts "td=" + td.to_s ;
      
      td1 = td + 1.5 ;
      puts "td1 = td + 1.5 = " + td1.to_s ;

      td2 = td + td1 ;
      puts "td2 = td2 = td + td1 = " + td2.to_s ;
      
      td2 += 3.14 ;
      puts "td2 += 3.14 = " + td2.to_s ;
    end 
  end

  ##################################################
  ##################################################
  ##################################################

  TimeDuration.test_initialize() ;
  TimeDuration.test_inc() ;
end

class TimeDulation < TimeDuration
end
