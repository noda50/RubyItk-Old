## -*- Mode:Ruby -*-
##Header:
##Title: Canvas Utility using tk
##Author: Itsuki Noda
##Type: class definition
##Date: 2004/12/01
##EndHeader:

## this is not completed to implement.
## the problem is that tk can not understand state command.

require 'tk' ;
require 'thread' ;
require 'myCanvasDevBase.rb' ;


class MyCanvasTk < MyCanvasDevBase

  attr :canvas,		TRUE ;
  attr :drawListFore,	TRUE ;
  attr :drawListBack,	TRUE ;

  attr :thread,		TRUE ;

  ##----------------------------------------------------------------------
  ## setup

  ##----------------------------------------
  ## initialize
  ##

  def initialize(param = {})
    super(param)

    setupWindow(param) ;
    @drawListFore = [] ;
    @drawListBack = [] ;
  end

  ##--------------------
  ## default size

  def dfltSizeX()
    return 512 ;
  end

  def dfltSizeY()
    return 512 ;
  end

  ##----------------------------------------
  ## setup window
  ##

  def setupWindow(param)
    
    setupWindowCanvas(param) ;
    setupWindowQuit(param) ;
  end

  def setupWindowCanvas(param)
    myWidth = width() ;
    myHeight = height() ;
    @canvas = TkCanvas.new {
      width(myWidth) ;
      height(myHeight) ;
      pack ;
    }
  end

  def setupWindowQuit(param) ;
    @quitbutton = TkButton.new() {
      text("quit") ;
      command { exit(1) ; } ;
      pack ;
    }
  end

  ##----------------------------------------------------------------------
  ## top facility
  ##

  ##----------------------------------------
  ## run

  def run()
    @thread = Thread::new{
      Tk.mainloop ;
    }
    @thread.run() ;  #  !!! <- key point !!!
    beginPage() ;
  end

  ##----------------------------------------
  ## finish

  def finish()
    endPage() ;
    @thread.run() ;  #  !!! <- key point !!!
    sleep ;
  end

  ##----------------------------------------
  ## flush

  def flush()

    ## hide fore objects

    @drawListFore.each{|obj|
#      obj.state('hidden') ;
    }

    ## swap fore and back objects

    drawList = @drawListFore ;
    @drawListFore = @drawListBack ;
    @drawListBack = drawList ;
    

    ## show new fore objects

    @drawListFore.each{|obj|
#      obj.state('normal') ;
    }
  end

  ##----------------------------------------
  ## begin/end page

  def beginPage(color="white") # if color=nil, copy from old buffer
    ##???
    clearPage(color) if(!color.nil?) ;
  end

  def endPage()
    flush() ;
  end

  ##----------------------------------------
  ## clear page

  def clearPage(color="white")
    while(!@drawListBack.empty?) 
      obj = @drawListBack.pop() ;
      @canvas.delete(obj) ;
    end

    obj = TkcRectangle.new(@canvas,0,0,width(),height(),
			   "fill" => color, "outline" => color) ;
    registerInBuffer(obj) ;
  end

  ##----------------------------------------------------------------------
  ## draw primitive

  def registerInBuffer(obj)
#    obj.state('hidden') ;
    @drawListBack.push(obj) ;
  end

  ##----------------------------------------
  ## draw dashed line
  ##

  def drawDashedLine(x0,y0,x1,y1,thickness=1,color="grey")
    ##???
  end

  ##----------------------------------------
  ## draw solid line
  ##

  def drawSolidLine(x0,y0,x1,y1,thickness=1,color="black")
    obj = TkcLine.new(@canvas,valX(x0),valY(y0),valX(x1),valY(y1)) ;
    obj.fill(color) ;
    registerInBuffer(obj) ;
  end

  ##----------------------------------------
  ## draw ellipse (circle)
  ##

  def drawEllipse(x,y,rx,ry,fillp,color="black")
    if(fillp) 
      obj = TkcOval.new(@canvas,valX(x-rx),valY(y-ry),valX(x+rx),valY(y+ry),
			'fill' => color, 'outline' => color) ;
    else
      obj = TkcOval.new(@canvas,valX(x-rx),valY(y-ry),valX(x+rx),valY(y+ry),
			'outline' => color) ;
    end
    registerInBuffer(obj) ;
  end

  ##----------------------------------------
  ## draw rectangle
  ##
  
  def drawRectangle(x,y,w,h,fillp,color="black")
    if(fillp) then
      obj = TkcRectangle.new(@canvas,valX(x),valY(y),valX(x+w),valY(y+h),
			     'fill' => color, 'outline' => color) ;
    else
      obj = TkcRectangle.new(@canvas,valX(x),valY(y),valX(x+w),valY(y+h),
			     'outline' => color) ;
    end
    registerInBuffer(obj) ;
  end
  
end
