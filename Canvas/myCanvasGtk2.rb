## -*- Mode:Ruby -*-
##Header:
##Title: Canvas Utility using Gtk
##Author: Itsuki Noda
##Type: class definition
##Date: 2004/12/01
##EndHeader:

require 'gtk2' ;
require 'thread' ;
require 'myCanvasDevBase.rb' ;


class MyCanvasGtk2 < MyCanvasDevBase

  attr :topwindow,	TRUE ;

  attr :hbox,		TRUE ;
  attr :vbox,		TRUE ;
  attr :topbar,		TRUE ;
  attr :bottombar,	TRUE ;
  attr :leftbar,	TRUE ;
  attr :rightbar,	TRUE ;
  attr :centerbox,	TRUE ;

  attr :canvas,		TRUE ;
  attr :drawable,	TRUE ;
  attr :buffer,		TRUE ;
  attr :currentbuffer,	TRUE ;

  attr :geometry,	TRUE ;
  attr :gc,		TRUE ;
  attr :color,		TRUE ; # color table
  attr :colormap,	TRUE ;

  attr :thread,		TRUE ;

  ##----------------------------------------------------------------------
  ## setup

  ##----------------------------------------
  ## initialize
  ##

  def initialize(param = {})
    super(param) ;

    setupWindow(param) ;
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
    @topwindow = Gtk::Window::new(Gtk::WINDOW_TOPLEVEL) ;
    @topwindow.set_title(param.fetch('title',"myGtkCanvas")) ;
    @topwindow.realize ;

#    @topwindow.signal_connect(Gtk::Widget::SIGNAL_EXPOSE_EVENT) do |win,evt|
#      expose_event(win,evt) ;
#    end

    setupWindowTopMiddleBottom(param) ;
    setupWindowLeftCenterRight(param) ;

    setupWindowCanvas(param) ;

    setupWindowQuit(param) ;

    @topwindow.show_all ;
  end

  ##--------------------
  ## setup top/middle/bottom

  def setupWindowTopMiddleBottom(param) 

    # vertical box
    @vbox = Gtk::VBox::new(false) ; 
    @topwindow.add(@vbox) ; 
    @vbox.show() ;

    #top bar
    @topbar = Gtk::HBox::new(false) ; 
    @vbox.add(@topbar) ; 
    @topbar.show() ;

    #middle bar
    @hbox = Gtk::HBox::new(false) ; 
    @vbox.add(@hbox) ; 
    @hbox.show() ;

    #bottom bar
    @bottombar = Gtk::HBox::new(false) ; 
    @vbox.add(@bottombar) ; 
    @bottombar.show() ;
  end

  ##--------------------
  ## setup left/center/right

  def setupWindowLeftCenterRight(param)
    @leftbar = Gtk::VBox::new(false) ; 
    @hbox.add(@leftbar) ;
    @leftbar.show() ;

    @centerbox = Gtk::VBox::new(false) ;
    @hbox.add(@centerbox) ;
    @centerbox.show() ;
    
    @rightbar = Gtk::VBox::new(false) ;
    @hbox.add(@rightbar) ;
    @rightbar.show() ;
  end

  ##--------------------
  ## setup canvas

  def setupWindowCanvas(param)
    @canvas = Gtk::DrawingArea::new() ;
    @canvas.set_usize(@sizeX,@sizeY) ;
    				# set_app_paintable is for v.1.2.9 or greater
    if(1.0208 < (Gtk::MAJOR_VERSION + 
		 Gtk::MINOR_VERSION * 0.01 + 
		 Gtk::MICRO_VERSION * 0.0001)) then
      @canvas.set_app_paintable(true) ;
    end
    @centerbox.add(@canvas) ;
    @canvas.show() ;

    @canvas.signal_connect(Gtk::Widget::SIGNAL_EXPOSE_EVENT) do |win,evt|
      expose_event(win,evt) ;
    end
    @canvas.signal_connect(Gtk::Widget::SIGNAL_CONFIGURE_EVENT){|w, e| 
      if(@drawable.nil?) 
	@drawable = @canvas.window ;

	@geometry = @drawable.get_geometry ;
	@sizeX = @geometry[2] ;
	@sizeY = @geometry[3] ;

	assignNewBuffer(false) ;

	prepareGC(true) ;
	assignBaseColors() ;
      end
    }
  end

  ##--------------------
  ## setup quit button

  def setupWindowQuit(param)
    pos = param.fetch('quitbutton','bottom') ;

    if(!pos.nil?) then
      @quitbutton = Gtk::Button::new("quit") ;

      case pos
      when 'left'
	@leftbar.add(@quitbutton) ;
      when 'right'
	@rightbar.add(@quitbutton) ;
      when 'top'
	@topbar.add(@quitbutton) ;
      when 'bottom'
	@bottombar.add(@quitbutton) ;
      else
	$stderr << "Error: unknown quit-button position: " << pos << "\n" ;
	fail ;
      end

      @quitbutton.signal_connect("clicked") {
	# Thread::main.kill() ;
	exit(0) ;
      }
    end
  end


  ##----------------------------------------------------------------------
  ## top facility
  ##

  ##----------------------------------------
  ## run

  def run()
    @thread = Thread::new{
      Gtk.main ;
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
    if(! @buffer.nil?) 
      @drawable.draw_pixmap(@gc,@buffer,0,0,0,0,width(),height()) ;
      @currentbuffer = @buffer ;
    end

    if(Thread.current != @thread)
      @thread.run() ;
    end
  end

  ##----------------------------------------
  ## begin/end page

  def beginPage(color="white") # if color=nil, copy from old buffer
    assignNewBuffer(color.nil?) ;
    clearPage(color) if(!color.nil?) ;
  end

  def endPage()
    flush() ;
  end

  ##----------------------------------------
  ## clear page

  def clearPage(color="white")
    @gc.set_foreground(getColor(color)) ;
    @buffer.draw_rectangle(@gc,true,0,0,width(),height()) ;
  end

  ##----------------------------------------------------------------------
  ## draw primitive

  ##----------------------------------------
  ## draw dashed line
  ##

  def drawDashedLine(x0,y0,x1,y1,thickness=1,color="grey")
    @gc.set_foreground(getColor(color)) ;
    @gc.set_line_attributes(thickness, Gdk::LINE_ON_OFF_DASH,
			    Gdk::CAP_NOT_LAST, Gdk::JOIN_MITER)    

    @buffer.draw_line(@gc,valX(x0),valY(y0),valX(x1),valY(y1)) ;
  end

  ##----------------------------------------
  ## draw solid line
  ##

  def drawSolidLine(x0,y0,x1,y1,thickness=1,color="black")
    @gc.set_foreground(getColor(color)) ;
    @gc.set_line_attributes(thickness, Gdk::LINE_SOLID, 
			    Gdk::CAP_NOT_LAST, Gdk::JOIN_MITER)    

    @buffer.draw_line(@gc,valX(x0),valY(y0),valX(x1),valY(y1)) ;
  end

  ##----------------------------------------
  ## draw ellipse (circle)
  ##

  def drawEllipse(x,y,rx,ry,fillp,color="black")
    @gc.set_foreground(getColor(color)) ;
    @gc.set_line_attributes(1, Gdk::LINE_SOLID, 
			    Gdk::CAP_NOT_LAST, Gdk::JOIN_MITER)    

    @buffer.draw_arc(@gc,fillp,valX(x-rx),valY(y-ry),scaleX(2*rx),scaleY(2*ry),
		       360 * 0, 360 * 64) ;
  end

  ##----------------------------------------
  ## draw rectangle
  ##
  
  def drawRectangle(x,y,w,h,fillp,color="black")
    @gc.set_foreground(getColor(color)) ;
    @gc.set_line_attributes(1, Gdk::LINE_SOLID,
			    Gdk::CAP_NOT_LAST, Gdk::JOIN_MITER) ;

    @buffer.draw_rectangle(@gc,fillp,valX(x),valY(y),scaleX(w),scaleY(h)) ;
  end

  ##----------------------------------------------------------------------
  ## utility

  ##----------------------------------------
  ## assignNewBuffer

  def assignNewBuffer(copyp = false) # if initp=true, copy from old buffer
    # create new buffer
    oldbuf = @buffer ;
    newbuf = Gdk::Pixmap::new(@drawable, width(), height(),-1) ;

    #copy from old buffer
    if(!oldbuf.nil? && copyp)
      newbuf.draw_pixmap(@gc, oldbuf, 0,0, 0,0,width(),height());
    end

    @buffer = newbuf ;
    @currentbuffer = oldbuf ;
  end

  ##----------------------------------------
  ## expose_event
  ##

  def expose_event(w,e)
    @drawable.draw_pixmap(@gc,@currentbuffer,0,0,0,0,width(),height()) ;
#    p(e.area) ;
    false ;
  end

  ##----------------------------------------
  ## color utility
  ##

  def assignBaseColors()
    @color = Hash::new() ;
    @colormap = Gdk::Colormap.get_system ;
  end

  RGBFILE = "/usr/lib/X11/rgb.txt" ;

  def getColor(colorname)
    col = @color[colorname] ;
    if(col.nil?) then
      f = File::new(RGBFILE) ;
      rval = -1 ; gval = -1 ; bval = -1 ;
      while(entry = f.gets)
	entry.strip! ;
	rstr,gstr,bstr,name = entry.split ;
	if(name == colorname) then
	  rval = rstr.to_i * 256 ;
	  gval = gstr.to_i * 256 ;
	  bval = bstr.to_i * 256 ;
	  break ;
	end
      end
      if(rval < 0) then
	if(colorname =~ /^\#([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])$/) then
	  rstr = $1 ; gstr = $2 ; bstr = $3 ;
	  rval = rstr.hex * 256 ; 
	  gval = gstr.hex * 256 ; 
	  bval = bstr.hex * 256 ; 
	else
	  $stderr << "unknown color name:" << colorname << "\n" ;
	end
      end
      col = assignColor(colorname,rval,gval,bval) ;
    end
    return col ;
  end

  def assignColor(color,rval,gval,bval) 
    c = Gdk::Color.new(rval,gval,bval) ;
    @color[color] = c ;
    @colormap.alloc_color(c,false,true) ;
    return c ;
  end
    
  ##----------------------------------------
  ## prepareGC
  ##

  def prepareGC(forcep)
    if(forcep || @gc.nil?) then
      @gc = Gdk::GC.new(@drawable) ;
    end
  end

end


  


