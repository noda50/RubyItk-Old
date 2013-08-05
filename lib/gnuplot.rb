## -*- Mode: ruby -*-
##! /usr/local/bin/ruby
##Header:
##Title: gnuplot utility
##Author: Itsuki Noda
##Type: class definition
##Date: 2004/12/01
##EndHeader:
##

##======================================================================
## Gnuplot class

##------------------------------------------------------------
## sample 1
#
# gplot = Gnuplot::new("x11") ; # or "tgif"
# gplot.setTitle("This is a test.") ;
# gplot.setXYLabel("X axis","Y axis") ;
# gplot.command('plot [0:10] x*x') ;
# gplot.close() ;

##------------------------------------------------------------
## sample 2
#
# Gnuplot::directPlot() {|gplot|
#   (0...10).each{|x|
#     gplot.dpXYPlot(x,x*x) ;
#     gplot.dpFlush() if dynamicP
#   }
# }

##------------------------------------------------------------
## sample 3
#
# gplot = Gnuplot::new() ;
# gplot.dpBegin() ;
# (0...10).each{|x|
#   gplot.dpXYPlot(x,x*x) ;
#   gplot.dpFlush() if dynamicP
# }
# gplot.dpEnd() ;
# gplot.close() ;

##------------------------------------------------------------
## sample 2
#
# Gnuplot::directMultiPlot(3) {|gplot|
#   gplot.dmpSetTitle(0,"foo") ;
#   gplot.dmpSetTitle(1,"bar") ;
#   gplot.dmpSetTitle(2,"baz") ;
#   (0...10).each{|x|
#     gplot.dmpXYPlot(0,x,x*x) ;
#     gplot.dmpXYPlot(1,x,sin(x)) ;
#     gplot.dmpXYPlot(2,x,cos(x)) ;
#     gplot.dmpFlush() if dynamicP 
#   }
# }

require 'tempfile' ;

class Gnuplot

  Colors = "-xrm 'gnuplot*line2Color:darkgreen'"

  @@command = "gnuplot #{Colors} -persist %s >& /dev/null" ;

  @@defaultTerm = "x11" ;
#  @@defaultTerm = "tgif" ;
  @@defaultFileNameBase = "foo" ;

  def Gnuplot.setTermFileBase(term, filebase = @@defaultFileNameBase)
    @@defaultTerm = term ;
    @@defaultFileNameBase = filebase ;
  end

  ##--------------------
  ## used for dynamic plotting
  DfltWorkfileBase = "RubyGnuplot" ;
  DfltPlotStyle = "w linespoints" ; 
  
  attr :strm, TRUE ;
  attr :m, TRUE ;
  attr :workstrm, TRUE ;
  attr :workfile, TRUE ;
  attr :datafile, TRUE ;
  attr :title,    TRUE ;
  attr :hline,    TRUE ;
  attr :scriptfile, TRUE ;
  attr :timeMode, true ;
  attr :sustainedMode, true ;
  attr :preValue, true ;

  ##--------------------
  ##
  def initialize(term = nil,
                 filenamebase = nil, 
                 comlineOpt = nil)
    term = @@defaultTerm if term.nil? ;
    filenamebase = @@defaultFileNameBase if filenamebase.nil? ;
    myopen(term, filenamebase, comlineOpt) ;
    if(!saveScript?())
      setTerm(term, filenamebase) ;
    end
    @hline = [] ;
    @timeMode = false ;
    @sustainedMode = false ;
    @preValue = {} ;
  end

  ##--------------------
  ##
  def myopen(term, filenamebase, comlineOpt) 
    if(term == "gplot" || term == :gplot)
      @scriptfile = filenamebase + ".gpl" ;
      @strm = open(@scriptfile, "w") ;
    else
      opt = comlineOpt ;
      opt = "" if opt.nil? ;
      @strm = open("|" + (@@command % opt) ,"w") ;
      #@strm = STDOUT ;
    end
  end

  ##--------------------
  ##
  def saveScript?()
    return !@scriptfile.nil? ;
  end

  ##--------------------
  ##
  def close()
    @strm.print("quit\n") ;
    @strm.close() ;
  end

  ##--------------------
  ##
  def setTerm(term,filenamebase = "foo") 
    termopt = "" ;
    setout = TRUE ;
    case(term)
    when "tgif", :tgif
      suffix="obj" ;
      termopt = "solid" ;
    when "postscript", :postscript, :ps
      suffix="ps" ;
    when "gplot", :gplot
      suffix="gp" ;
    else
      setout = FALSE ;
    end

    @strm.printf("set term %s %s\n",term,termopt) ;
    
    
    if(setout) then
      @strm.printf("set out \"%s.%s\"\n",filenamebase,suffix) ;
    end
  end

  ##--------------------
  ## 
  def setTitle(title) 
    @strm.printf("set title \"%s\"\n",title) ;
  end

  ##--------------------
  ## 
  def setTimeFormat(xy,inFormat, outFormat = nil)
    case(xy)
    when :x
      command("set xdata time") ;
      command("set format x \"#{outFormat}\"") if (outFormat) ;
    when :y
      command("set ydata time") ;
      command("set format y \"#{outFormat}\"") if (outFormat) ;
    when :xy
      command("set xdata time") ;
      command("set ydata time") ;
      command("set format x \"#{outFormat}\"") if (outFormat) ;
      command("set format y \"#{outFormat}\"") if (outFormat) ;
    else
      raise "unknown xy-flag for setTimeFormat:" + xy.to_s ;
    end
    @timeMode = true ;
    command("set timefmt \"#{inFormat}\"") ;
  end

  ##--------------------
  ## 
  def setXYLabel(xlabel,ylabel)
    @strm.printf("set xlabel \"%s\"\n",xlabel) ;
    @strm.printf("set ylabel \"%s\"\n",ylabel) ;
  end

  ##--------------------
  ## 
  def setSustainedMode(mode = true)
    @sustainedMode = mode ;
  end

  ##--------------------
  ## 
  def setKeyConf(configstr) # see gnuplot set key manual
                         # useful keyword: left, right, top, bottom
                         #                 outside, below
                          
    @strm.printf("set key %s\n",configstr) ;
  end

  ##--------------------
  ##
  def setParam(param, value) ;
    @strm.printf("set %s %s\n", param, value) ;
  end

  ##--------------------
  ## 
  def pushHLine(label,value,style = nil)
    @hline.push([label, value, style]) ;
  end

  ##--------------------
  ##
  def command(comstr)
    if(comstr.is_a?(Array)) 
      comstr.each{ |com| command(com) ; } ;
    end
    
    @strm.print(comstr) ;
    @strm.print("\n") ;
  end

  ##------------------------------------------------------------
  ## direct ploting

  ##--------------------
  ## direct plot begin
  def dpBegin() 
    @workstrm = Tempfile::new(DfltWorkfileBase) ;
    @workfile = @workstrm.path ;
    @datafile = nil ;
  end

  ##--------------------
  ## set datafile to save

  def dpSetDatafile(datafilename)
    @datafile = datafilename ;
  end

  ##--------------------
  ## direct plot 
  def dpXYPlot(x,y) ;
    if(@sustainedMode && @preValue[:main])
      @workstrm << x << " " << @preValue[:main] << "\n" ;
    end
    @workstrm << x << " " << y << "\n" ;

    @preValue[:main] = y ;
  end

  ##--------------------
  ## direct plot flush and show
  def dpFlush(rangeopt = "", styles = DfltPlotStyle) 
    @workstrm.flush ;
    dpShow(rangeopt, styles) ;
  end

  ##--------------------
  ## direct plot end
  def dpEnd(showp = TRUE, rangeopt = "", styles = DfltPlotStyle) 
    @workstrm.close() ;

    # copy data file for save
    if(!@datafile.nil?) then
      system(sprintf("cp %s %s",@workfile,@datafile)) ;
    end

    # show result
    if(showp) then
      dpShow(rangeopt,styles) ;
    end
  end

  ##--------------------
  ## direct plot show result
  def dpShow(rangeopt = "", styles = DfltPlotStyle) 
    styles = "using 1:2 " + styles if(@timeMode) ;
    datafile = @workfile ;
    if(saveScript?())
      datafile = '-' ;
    end
    com = sprintf("plot %s \"%s\" %s",rangeopt,datafile,styles) ;

    @hline.each{|line|
      label = line[0] ;
      value = line[1] ;
      style = (line[2].nil?) ? "dots" : line[2] ;

      com += (", %s title '%s' with %s" % [value.to_s, label, style]) ; 
      
    }

    command(com) ;

    if(saveScript?())
      open(@workfile){|strm|
        strm.each{|line|
          @strm << line
        }
      }
      @strm << "e\n" ;
    end
  end

  ##------------------------------------------------------------
  ## direct multiple ploting

  ##--------------------
  ## direct multiple plot begin
  def dmpBegin(m)
    if(m.is_a?(Integer))
      @m = m ;
      @workstrm = Array::new(m) ;
      @workfile = Array::new(m) ;
      @datafile = Array::new(m) ;
      @title = Array::new(m) ;
      @layerList = (0...m) ;
      @workcount = Hash.new ;
    elsif(m.is_a?(Array))
      @m = m.size ;
      @workstrm = Hash.new ;
      @workfile = Hash.new ;
      @datafile = Hash.new ;
      @title = Hash.new ;
      @layerList = m ;
      @workcount = Hash.new ;
    else
      raise "unknown index for multiple plot: #{m}" ;
    end

    @localStyle = {} ;

    @layerList.each{|i| 
      @workstrm[i] = Tempfile::new(DfltWorkfileBase) ;
      @workstrm[i] << '#' << "\n" ;
      @workfile[i] = @workstrm[i].path ;
      @datafile[i] = nil ;

#      if(i.is_a?(Array)) then
#        @title[i] = i.join(',') ;
#      else
#        @title[i] = i.to_s ;
#      end
      @title[i] = i.inspect ;

      @workcount[i] = 0 ;
    }
  end

  ##--------------------
  ## set datafile to save

  def dmpSetDatafile(k,datafilename)
    @datafile[k] = datafilename ;
  end

  ##--------------------
  ## set title for each plot

  def dmpSetTitle(k,title) ;
    @title[k] = title ;
  end

  def dmpSetStyle(k,style) ;
    @localStyle[k] = style ;
  end

  ##--------------------
  ## direct multiple plot end
  def dmpXYPlot(k,x,y)
    if(@sustainedMode && @preValue[k])
      @workstrm[k] << x << " " << @preValue[k] << "\n" ;
    end
    @workcount[k] += 1;
    @workstrm[k] << x << " " << y << "\n" ;

    @preValue[k] = y ;
  end

  ##--------------------
  ## direct multiple plot end
  def dmpFlush(rangeopt = "", styles = DfltPlotStyle)
    @layerList.each{|k|
      @workstrm[k].flush() ;
    }
    dmpShow(rangeopt, styles) ;
  end

  ##--------------------
  ## direct multiple plot end
  def dmpEnd(showp = TRUE, rangeopt = "", styles = DfltPlotStyle)
    @layerList.each{ |i|
      @workstrm[i].close() ;

      # copy data file for save
      if(!@datafile[i].nil?) then
	system(sprintf("cp %s %s",@workfile[i],@datafile[i])) ;
      end
    }

    # show result
    if(showp) then
      dmpShow(rangeopt,styles) ;
    end
  end

  ##--------------------
  ## direct multi plot show result
  def dmpShow(rangeopt = "", styles = DfltPlotStyle)
    com = sprintf("plot %s",rangeopt) ;
    firstp = TRUE ;

    inlineDataList = [] ;

    @layerList.each{|k|
      next if (@workcount[k] <= 0) ;
      if(saveScript?())
        inlineDataList.push(@workfile[k]) ;
        file = '-' ;
      else
        file = @workfile[k] ;
      end
      if(firstp) then
	com += " " ;
	firstp = FALSE ;
      else
	com += ", " ;
      end

      localstyle = @localStyle[k] || styles ;
      using = (@timeMode ? "using 1:2" : "") ;

      if(title[k].nil?) then
	com += sprintf("\"%s\" %s %s",file,using,localstyle) ;
      else
	com += sprintf("\"%s\" %s t \"%s\" %s",file,using,
                       title[k],localstyle) ;
      end
    }

    @hline.each{|line|
      label = line[0] ;
      value = line[1] ;
      style = (line[2].nil?) ? "dots" : line[2] ;

      com += (", %s title '%s' with %s" % [value.to_s, label, style]) ; 
      
    }

    command(com) ;

    inlineDataList.each{|datafile|
      open(datafile){|strm|
        strm.each{|line|
          @strm << line ;
        }
      }
      @strm << "e\n" ;
    }

  end

end

##------------------------------------------------------------
## direct ploting toplevel

def Gnuplot::directPlot(rangeopt = "", styles = Gnuplot::DfltPlotStyle) 
  gplot = Gnuplot::new() ;
  gplot.dpBegin() ;
  yield(gplot) ;
  gplot.dpEnd(TRUE, rangeopt,styles) ;
  gplot.close() ;
end

##------------------------------------------------------------
## direct multi ploting toplevel

def Gnuplot::directMultiPlot(m, rangeopt = "", 
			     styles = Gnuplot::DfltPlotStyle) 
  gplot = Gnuplot::new() ;
  gplot.dmpBegin(m) ;
  yield(gplot) ;
  gplot.dmpEnd(TRUE, rangeopt,styles) ;
  gplot.close() ;
end

##------------------------------------------------------------
## direct ploting toplevel

def Gnuplot::switchableDirectPlot(switch,	## true or false
                                  rangeopt = "", 
                                  styles = Gnuplot::DfltPlotStyle) 
  gplot = nil ;
  if(switch)
    gplot = Gnuplot::new() ;
    gplot.dpBegin() ;
  end

  yield(gplot) ;
  
  if(switch)
    gplot.dpEnd(TRUE, rangeopt,styles) ;
    gplot.close() ;
  end
end

##------------------------------------------------------------
## direct multi ploting toplevel

def Gnuplot::switchableDirectMultiPlot(switch, ## true or false
                                       m, 
                                       rangeopt = "", 
                                       styles = Gnuplot::DfltPlotStyle) 
  gplot = nil ;
  if(switch)
    gplot = Gnuplot::new() ;
    gplot.dmpBegin(m) ;
  end

  yield(gplot) ;
  
  if(switch)
    gplot.dmpEnd(TRUE, rangeopt,styles) ;
    gplot.close() ;
  end
end

######################################################################
######################################################################
######################################################################
if(__FILE__ == $0) then

  ##----------------------------------------
  ## dynamic plot (flush)
  def test00() ;
    gplot = Gnuplot::new("x11") ;
    gplot.dpBegin() ;
    range = "[0:10][0:100]" ;
    (0...100).each{|k|
      x = 0.1 * k ;
      gplot.dpXYPlot(x,x*x) ;
      gplot.dpFlush(range) ;
      sleep 0.01 ;
    }
    gplot.dpEnd(range) ;
    gplot.close() ;
  end

  ##----------------------------------------
  ## dynamic multi plot (flush)
  def test01() ;
    range = "[0:10][-1:1]" ;
    Gnuplot::directMultiPlot(3,range) {|gplot|
      gplot.dmpSetTitle(0,"foo") ;
      gplot.dmpSetTitle(1,"bar") ;
      gplot.dmpSetTitle(2,"baz") ;
      (0...100).each{|k|
        x = 0.1 * k ;
        gplot.dmpXYPlot(0,x,x*x) ;
        gplot.dmpXYPlot(1,x,Math::sin(x)) ;
        gplot.dmpXYPlot(2,x,Math::cos(x)) ;
        gplot.dmpFlush(range) ;
        sleep 0.1 ;
      }
    }
  end

  ##----------------------------------------
  ## time format 
  def test02() ;
    Gnuplot::directPlot("","w l"){|gplot|
      gplot.setTimeFormat(:x,"%Y-%m-%dT%H:%M") ;
      
      time = Time::now() ;
      (0...10).each{|i|
        x = time.strftime("%Y-%m-%dT%H:%M") ;
        y = rand(100) ;
        gplot.dpXYPlot(x,y) ;
        time += 10*60*60
      }
    }
  end

  ##----------------------------------------
  ## time format 
  def test03() ;
    Gnuplot::directMultiPlot([:a],"","w l"){|gplot|
      gplot.setTimeFormat(:x,"%Y-%m-%dT%H:%M","%d-%H") ;
      
      time = Time::now() ;
      (0...10).each{|i|
        x = time.strftime("%Y-%m-%dT%H:%M") ;
        y = rand(100) ;
        gplot.dmpXYPlot(:a,x,y) ;
        time += 10*60*60
      }
    }
  end

  ##----------------------------------------
  ##----------------------------------------
  ##----------------------------------------
#  test00() ;
#  test01() ;
#  test02() ;
  test03() ;

end



