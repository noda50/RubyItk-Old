## -*- Mode:Ruby -*-
##Header:
##Title: Canvas Device base class
##Author: Itsuki Noda
##Type: class definition
##Date: 2004/12/01
##EndHeader:

require 'tempfile' ;

## for the compativility with version 1.8.5 and 1.8.7
if(Tempfile.new(['foo', '.xpm']).path !~ /.xpm$/)
  class Tempfile
    def make_tmpname(basename, n)
      if(basename.is_a?(Array))
        sprintf('%s.%d.%d%s', basename[0], $$, n, basename[1])
      else
        sprintf('%s.%d.%d', basename, $$, n)
      end
    end
  end
  
end



##======================================================================
class MyCanvasDevBase

  attr :sizeX, true ;	# width
  attr :sizeY, true ;	# height
  attr :shiftX, true ;
  attr :shiftY, true ;
  attr :scaleX, true ;
  attr :scaleY, true ;

  attr :boudaryMinX, true ;
  attr :boudaryMinY, true ;
  attr :boudaryMaxX, true ;
  attr :boudaryMaxY, true ;

  attr :noExitWhenQuit,  true ;

  attr :originalImageFileName, true ;
  attr :convertedImageFile, true ; ## a Tempfile

  ##----------------------------------------------------------------------
  ## initialize
  ##

  def initialize(param = {})
#    setSize(szX,szY,scale,centerp) ;
    setSizeByParam(param) ;
    setBackgroundImage(param) ;

    @noExitWhenQuit = false ;
  end

  ##----------------------------------------------------------------------
  ## set param
  ##

  ##----------------------------------------
  ## default size

  def dfltSizeX()
    return 1024 ;
  end

  def dfltSizeY()
    return 1024 ;
  end

  def dfltScale()
    return 20 ;
  end

  ##----------------------------------------
  ## setSize by param table

  def setSizeByParam(param)
    # get image size if specified
    (imgWidth, imgHeight) = (param['image'] ?
                             getImageSizeFromFile(param['image']) :
                             [nil, nil]) ;
    # get width/height
    width = param.fetch('width', imgWidth || dfltSizeX()) ;
    height = param.fetch('height', imgHeight || dfltSizeY()) ;

    setSize(width, height,
	    param.fetch('scale',dfltScale()),param.fetch('centerp',FALSE)) ;
  end

  ##----------------------------------------
  ## setSize

  def setSize(szX,szY,scale,centerp=FALSE)
    szX = dfltSizeX() if szX.nil? ;
    szY = dfltSizeY() if szY.nil? ;
    scale = dfltScale() if scale.nil? ;
    centerp = FALSE if scale.nil? ;

    @sizeX = szX ;
    @sizeY = szY ;

    if(centerp)
      setShift(szX/2,szY/2) ;
      setBoundaryBox(-szX/2,-szY/2,szX/2,szY/2) ;
    else
      setShift(0,0) ;
      setBoundaryBox(0,0,szX,-szY) ;
    end
    setScale(scale) ;
  end

  ##----------------------------------------
  ## setShift

  def setShift(sx,sy) 
    @shiftX = sx ;
    @shiftY = sy ;
  end

  ##----------------------------------------
  ## setScale

  def setScale(scale)
    setScaleX(scale) ;
    setScaleY(scale) ;
  end

  ##--------------------
  ## setScaleX

  def setScaleX(scale) 
    @scaleX = scale ;
  end

  ##--------------------
  ## setScaleY

  def setScaleY(scale) 
    @scaleY = scale ;
  end

  ##--------------------
  ## getScaleX

  def getScaleX()
    return @scaleX ;
  end

  ##--------------------
  ## getScaleY

  def getScaleY()
    return @scaleY ;
  end


  ##----------------------------------------
  ## setScaleShift by boundary box

  def setScaleShiftByBoundaryBox(x0,y0,x1,y1)
    setBoundaryBox(x0,y0,x1,y1) ;
    setScaleShiftByBoundaryBoxBody() ;
  end

  def setBoundaryBox(x0,y0,x1,y1)
    @boundaryMinX = min(x0,x1) ; @boundaryMaxX = max(x0,x1) ;
    @boundaryMinY = min(y0,y1) ; @boundaryMaxY = max(y0,y1) ;
  end

  def setScaleShiftByBoundaryBoxBody() 
    scaleX = @sizeX / (@boundaryMaxX - @boundaryMinX) ;
    scaleY = @sizeY / (@boundaryMaxY - @boundaryMinY) ;

    scale = min(scaleX,scaleY) ;
    offsetX = -@boundaryMinX * scale ;
    offsetY = -@boundaryMinY * scale ;

    setScale(scale) ;

    setShift(offsetX,offsetY) ;
  end

  def min(a,b)
    if(a > b) then
      return b ;
    else
      return a ;
    end
  end

  def max(a,b)
    if(a > b) then
      return a ;
    else
      return b ;
    end
  end

  ##----------------------------------------------------------------------
  ## calc scale/shifted value
  ##

  ##----------------------------------------
  ## width/height

  def width
    return @sizeX ;
  end

  def height
    return @sizeY ;
  end

  ##----------------------------------------
  ## scaled values

  def scaleFltX(x) 
    return x * @scaleX ;
  end

  def scaleFltY(y) 
    return y * @scaleY ;
  end

  ##----------------------------------------
  ## scaled and shifted values

  def valFltX(x)
    return @shiftX + scaleFltX(x) ;
  end

  def valFltY(y)
    return @shiftY + scaleFltY(y) ;
  end

  ##----------------------------------------
  ## scaled values in integer

  def scaleX(x) 
    return scaleFltX(x).to_i ;
  end

  def scaleY(y) 
    return scaleFltY(y).to_i ;
  end

  ##----------------------------------------
  ## scaled and shifted values in integer

  def valX(x)
    return valFltX(x).to_i ;
  end

  def valY(y)
    return valFltY(y).to_i ;
  end

  ##----------------------------------------
  ## get original value

  def orgX(x)
    return unscaleX(x.to_f - @shiftX)
  end

  def orgY(y)
    return unscaleY(y.to_f - @shiftY)
  end
 
  def unscaleX(x)
    return x.to_f/@scaleX ;
  end

  def unscaleY(y)
    return y.to_f/@scaleY ;
  end

  ##----------------------------------------------------------------------
  ## toplevel
  ##

  ##----------------------------------------
  ## run [!!! should be defined in subclass!!!] 

  def run()
    $stderr.printf("You must define run().\n") ;
    fail ;
  end

  ##----------------------------------------
  ## waitQuit()

  def waitQuit()
    ## do noting default
  end

  ##----------------------------------------
  ## noExitWhenQuit()

  def noExitWhenQuit(flag = true)
    @noExitWhenQuit = flag ;
  end

  ##----------------------------------------
  ## finish

  def finish()
    $stderr.printf("You must define finish().\n") ;
    fail ;
  end

  ##----------------------------------------
  ## flush

  def flush()
  end

  ##----------------------------------------
  ## begin/end Page [!!! should be defined in subclass!!!] 

  def beginPage(color="white") # if color=nil copy from old buffer
    $stderr.printf("You must define beginPage().\n") ;
    fail ;
  end

  def endPage()
    $stderr.printf("You must define endPage().\n") ;
    fail ;
  end

  def clearPage(color="white")
    $stderr.printf("You must define clearPage().\n") ;
    fail ;
  end

  ##----------------------------------------
  ## safty call for block

  def saftyCall(*args, &block)
    begin
      block.call(*args) ;
    rescue => xpt ;
      $stderr << ("Exception: %s\n" % xpt.message) ;
      $stderr << ("    where\n") ;
      xpt.backtrace.each{ |info|
	$stderr << ("\t%s\n" % info.to_s) ;
      }
    end
  end

  ##----------------------------------------
  ## page

  def page(bgcolor="white",&block)
    beginPage(bgcolor) ;
    saftyCall(&block) ;
    endPage() ;
  end

  ##----------------------------------------
  ## singlePage

  def singlePage(bgcolor="white",&block)
    run() ;
    page(bgcolor,&block) ;
    finish() ;
  end

  ##----------------------------------------
  ## multiPage

  def multiPage(&block)
    run() ;
    saftyCall(&block) ;
    finish() ;
  end

  ##----------------------------------------
  ## animation

  def animation(iteration,interval=0,bgcolor="white",&block)
    begin
      run() ;

      if(iteration == true)
	animBodyEternal(interval,bgcolor,&block) ;
      elsif(iteration.is_a?(Integer))
	animBodyInt(iteration,interval,bgcolor,&block) ;
      elsif(iteration.respond_to?("each"))
	animBodyEach(iteration,interval,bgcolor,&block) ;
      else
	$stderr << "Error: unsupported iteration type :" << iteration << "\n" ;
	fail ;
      end
    rescue => exception then
      abort ;
    ensure
      finish() ;
    end
  end

  ##--------------------
  ## animation body eternal loop

  def animBodyEternal(interval=0,bgcolor="white",&block)
    i = 0 ;
    while(true) do
      page(bgcolor) { saftyCall(i,&block) ; } ;
      sleep(interval) if(interval>0) ;
      i += 1 ;
    end
  end

  ##--------------------
  ## animation body int loop

  def animBodyInt(loopN,interval=0,bgcolor="white",&block)
    (0...loopN).each { |i|
      page(bgcolor) { saftyCall(i,&block) ; } ;
      sleep(interval) if (interval>0) ;
    }
  end

  ##--------------------
  ## animation body each loop

  def animBodyEach(iteration,interval=0,bgcolor="white",&block)
    iteration.each { |i|
      page(bgcolor) { saftyCall(i,&block) ; } ;
      sleep(interval) if (interval>0) ;
    }
  end

  ##----------------------------------------------------------------------
  ## draw facility
  ##

  ##----------------------------------------
  ## draw line

  ##--------------------
  ## dashed line [!!! should be defined in subclass!!!] 

  def drawDashedLine(x0,y0,x1,y1,thickness=1,color="grey") ;
    $stderr.printf("You must define drawDashedLine().\n") ;
    fail ;
  end

  ##--------------------
  ## solid line [!!! should be defined in subclass!!!] 

  def drawSolidLine(x0,y0,x1,y1,thickness=1,color="black") ;
    $stderr.printf("You must define drawSolidLine().\n") ;
    fail ;
  end

  ##----------------------------------------
  ## draw circle

  ##--------------------
  ## draw circle body [!!! should be defined in subclass!!!] 

  def drawCircle(x,y,r,fillp,color="black")
    drawEllipse(x,y,r,r,fillp,color) ;
  end

  ##--------------------
  ## empty circle 

  def drawEmptyCircle(x,y,r,color="black")
    drawCircle(x,y,r,false,color) ;
  end

  ##--------------------
  ## filled circle 

  def drawFilledCircle(x,y,r,color="black")
    drawCircle(x,y,r,true,color) ;
  end

  ##--------------------
  ## framed circle 

  def drawFramedCircle(x,y,r,framecolor="black",fillcolor="white")
    drawFilledCircle(x,y,r,fillcolor) ;
    drawEmptyCircle(x,y,r,framecolor) ;
  end

  ##----------------------------------------
  ## draw ellipse

  ##--------------------
  ## draw ellipse body [!!! should be defined in subclass!!!] 

  def drawEllipse(x,y,rx,ry,fillp,color="black")
    $stderr.printf("You must define drawEllipse.\n") ;
    fail ;
  end

  ##--------------------
  ## empty ellipse 

  def drawEmptyEllipse(x,y,rx,ry,color="black")
    drawEllipse(x,y,rx,ry,false,color) ;
  end

  ##--------------------
  ## filled ellipse 

  def drawFilledEllipse(x,y,rx,ry,color="black")
    drawEllipse(x,y,rx,ry,true,color) ;
  end

  ##--------------------
  ## framed ellipse 

  def drawFramedEllipse(x,y,rx,ry,framecolor="black",fillcolor="white")
    drawFilledEllipse(x,y,rx,ry,fillcolor) ;
    drawEmptyEllipse(x,y,rx,ry,framecolor) ;
  end

  ##----------------------------------------
  ## draw rectangle
  ##
  
  ##--------------------
  ## draw rectangle body [!!! should be defined in subclass!!!] 

  def drawRectangle(x,y,w,h,fillp,color="black")
    $stderr.printf("You must define drawRectangle.\n") ;
    fail ;
  end

  ##--------------------
  ## empty rectangle

  def drawEmptyRectangle(x,y,w,h,color="black")
    drawRectangle(x,y,w,h,false,color) ;
  end

  ##--------------------
  ## filled rectangle

  def drawFilledRectangle(x,y,w,h,color="black") 
    drawRectangle(x,y,w,h,true,color) ;
  end

  ##--------------------
  ## framed rectangle

  def drawFramedRectangle(x,y,w,h,framecolor="black",fillcolor="white")
    drawFilledRectangle(x,y,w,h,fillcolor) ;
    drawEmptyRectangle(x,y,w,h,framecolor) ;
  end

  ##----------------------------------------
  ## draw rectangle by abs pos
  ##

  ##--------------------
  ## draw rectangleAbs body 

  def drawRectangleAbs(x0,y0,x1,y1,fillp,color="black")
    drawRectangle(x0,y0,x1-x0,y1-y0,fillp,color) ;
  end

  ##--------------------
  ## empty rectangleAbs

  def drawEmptyRectangleAbs(x0,y0,x1,y1,color="black")
    drawRectangleAbs(x0,y0,x1,y1,false,color) ;
  end

  ##--------------------
  ## filled rectangleAbs

  def drawFilledRectangleAbs(x0,y0,x1,y1,color="black") 
    drawRectangleAbs(x0,y0,x1,y1,true,color) ;
  end

  ##--------------------
  ## framed rectangleAbs

  def drawFramedRectangleAbs(x0,y0,x1,y1,framecolor="black",fillcolor="white")
    drawFilledRectangleAbs(x0,y0,x1,y1,fillcolor) ;
    drawEmptyRectangleAbs(x0,y0,x1,y1,framecolor) ;
  end

  ##----------------------------------------
  ## draw polygon
  ##
  
  ##--------------------
  ## draw polygon body [!!! should be defined in subclass!!!] 

  def drawPolygon(pointList,fillp,color="black")
    $stderr.printf("You must define drawPolygon.\n") ;
    fail ;
  end

  ##--------------------
  ## empty polygon

  def drawEmptyPolygon(pointList,color="black")
    drawPolygon(pointList,false,color) ;
  end

  ##--------------------
  ## filled polygon

  def drawFilledPolygon(pointList,color="black") 
    drawPolygon(pointList,true,color) ;
  end

  ##--------------------
  ## framed polygon

  def drawFramedPolygon(pointList,framecolor="black",fillcolor="white")
    drawFilledPolygon(pointList,fillcolor) ;
    drawEmptyPolygon(pointList,framecolor) ;
  end

  ##----------------------------------------
  ## draw text
  ##

  def drawText(x,y,text,fontSize = 14, fontFamily = :times, color = "black") 
    $stderr.printf("You must define drawText.\n") ;
    fail ;
  end

  ##----------------------------------------
  ## draw image
  ##

  def drawImage(xdest,ydest,src,
                xsrc = 0, ysrc = 0, width = -1, height = -1)
    $stderr.printf("You must define drawImage.\n") ;
    fail ;
  end

  ##----------------------------------------
  ## get image from file
  ##

  def getImageFromFile(file) 
    $stderr.printf("You must define getImageFromFile.\n") ;
    fail ;
  end

  ##----------------------------------------------------------------------
  ## show status info
  ##

  ##--------------------
  ## add status info entry

  def addStatusInfoEntry(name,value = "")
    $stderr << "Warninig: addStatusInfoEntry is not supported yet in this device." ;
    $stderr << "\n" ;
  end

  ##--------------------
  ## set status info

  def setStatusInfo(name,value)
    $stderr << "Warninig: setStatusInfo is not supported yet in this device." ;
    $stderr << "\n" ;
  end

  ##----------------------------------------------------------------------
  ## operation for background image
  ##
  
  ##--------------------
  ## set status info

  def setBackgroundImage(param)
    @originalImageFileName = param['image'] ;
    if(@originalImageFileName)
      width = @sizeX ; 
      height = @sizeY ;
      @convertedImageFile = convertToXpmFile(@originalImageFileName,
                                             { :width => width,
                                               :height => height }) ;
    end
  end



  ##======================================================================
  ## image file operation
  module Utility

    ##--------------------
    ## get image size from file

    def getImageSizeFromFile(imageFile)
      open("| identify -format \"%w %h\" #{imageFile}", "r"){|com|
        result = com.gets() ;
        size = result.split(/\s+/).map{|d| d.to_i} ;
        return size ;
      }
    end

    ##--------------------
    ## convert image to xpm

    def convertToXpmFile(imageFile, conf = {})
      originalSize = getImageSizeFromFile(imageFile) ;
      width = conf[:width] || originalSize[0] ;
      height = conf[:height] || originalSize[1] ;

      tmpImageFile = Tempfile.new(['myCanvas','.xpm']) ;
      tmpImageFile.close() ;
      system("convert #{imageFile} -resize \"#{width}x#{height}>\" #{tmpImageFile.path}") ;
      return tmpImageFile ;
    end

  end ## module Utility

  include Utility ;
  extend Utility ;

end


