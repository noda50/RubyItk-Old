#! /usr/bin/ruby
## -*- Mode:Ruby -*-

require "myCanvas.rb" ;

##----------------------------------------------------------------------
## test1 

def test1() 

#  canvas = MyCanvas.new('tgif',
  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.run() ;

  (0...10).each { |i|
    canvas.beginPage(nil) ;
    x = Math.cos((i.to_f/10.0) * 3.14) ;
    y = Math.sin((i.to_f/10.0) * 3.14) ;
    canvas.drawSolidLine(0,0,x,y,1,"black") ;
    canvas.endPage() ;
    p(i) ;
    sleep(0.1) ;
  }
  canvas.finish() ;

end

##----------------------------------------------------------------------
## test2  canvas.page

def test2() 

#  canvas = MyCanvas.new('tgif',
  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.run() ;

  (0...10).each { |i|
    canvas.page(nil) {
      x = Math.cos((i.to_f/10.0) * 3.14) ;
      y = Math.sin((i.to_f/10.0) * 3.14) ;
      canvas.drawSolidLine(0,0,x,y,1,"black") ;
    }
    p(i) ;
    sleep(0.1) ;
  }
  canvas.finish() ;

end

##----------------------------------------------------------------------
## test3  canvas.multiPage

def test3() 

#  canvas = MyCanvas.new('tgif',
  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.multiPage() {

    (0...10).each { |i|
      canvas.page() {
	x = Math.cos((i.to_f/10.0) * 3.14) ;
	y = Math.sin((i.to_f/10.0) * 3.14) ;
	canvas.drawSolidLine(0,0,x,y,1,"black") ;
      }
      p(i) ;
      sleep(0.1) ;
    }
  }

end


##----------------------------------------------------------------------
## test4  canvas.singlePage

def test4() 

#  canvas = MyCanvas.new('tgif',
  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.singlePage("white") {
    canvas.drawSolidLine(0,0,1,0,1,"black") ;
    canvas.drawSolidLine(1,0,1,1,2,"blue") ;
    canvas.drawDashedLine(1,1,0,1,1,"green") ;
    canvas.drawDashedLine(0,1,0,0,2,"red") ;

    canvas.drawFramedCircle(-1,-1,1,"PaleGreen","pink") ;

    canvas.drawFramedRectangle(1,1,1,1,"grey30","grey70") ;

    canvas.drawFramedRectangleAbs(-0.3,-0.3,0.3,0.3,"red","purple") ;
  }

end

##----------------------------------------------------------------------
## test5  canvas.animation

def test5() 

  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.animation(true,0.01) {|i|
    h = i.to_f / 10.0 ;
    x = Math.cos(h) ;
    y = Math.sin(h) ;
    canvas.drawFilledCircle(0,0,1,"yellow") ;
    canvas.drawSolidLine(0,0,x,y,1,"black") ;
  }

end

##----------------------------------------------------------------------
## test6  canvas.animation

def test6() 

  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.animation(100,0.01) {|i|
    h = i.to_f / 10.0 ;
    x = Math.cos(h) ;
    y = Math.sin(h) ;
    canvas.drawFilledCircle(0,0,1,"yellow") ;
    canvas.drawSolidLine(0,0,x,y,1,"black") ;
  }

end

##----------------------------------------------------------------------
## test7  canvas.animation

def test7() 

  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.animation((0...100),0.01) {|i|
    h = i.to_f / 10.0 ;
    x = Math.cos(h) ;
    y = Math.sin(h) ;
    canvas.drawFilledCircle(0,0,1,"yellow") ;
    canvas.drawSolidLine(0,0,x,y,1,"black") ;
  }

end

##----------------------------------------------------------------------
## test8 picture

def test8() 
  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> true,
			  'filename'	=> "foo.obj",
			  '' 		=> nil}) ;

  canvas.run() ;
  canvas.page() {
    x = 1
    y = 2
    canvas.drawSolidLine(0,0,x,y,1,"black") ;
  }
  canvas.finish() ;

end


##----------------------------------------------------------------------
## test9 draw image

def test9() 

  imageFile = 'soccer.ball.250.xpm' ;
  newImage = MyCanvas.convertToXpmFile('~/lib/image/WorldCup.jpg',
                                       { :width => 512,
                                         :height => 512 }) ;
  p newImage ;

  canvas = MyCanvas.new('gtk',
			{ 'width'	=> 512,
			  'height'	=> 512,
			  'scale'	=> 100,
			  'centerp'	=> false,
			  '' 		=> nil}) ;

  canvas.run() ;
  canvas.page('white') {
    (image, mask) = canvas.getImageFromFile(newImage.path) ;
    canvas.drawFilledRectangle(0,0,512,512,'white')
    canvas.drawImage(0,0,image) ;
  }
  canvas.finish() ;

end

##----------------------------------------------------------------------
## test10 background

def test10() 

  canvas = MyCanvas.new('gtk',
			{ 'image' => '~/lib/image/WorldCup.jpg',
			  'centerp'	=> false,
			  '' 		=> nil}) ;
  canvas.run() ;
  canvas.page(){
    canvas.drawSolidLine(0,0,300,300,3,"red") ;
  }
  canvas.finish() ;
end

##----------------------------------------------------------------------
## test11 background anime

def test11() 

  canvas = MyCanvas.new('gtk',
			{ 'image' => '~/lib/image/WorldCup.jpg',
                          'scale' => 1.0,
			  'centerp'	=> false,
			  '' 		=> nil}) ;
  canvas.animation((0...300), 0.001){|i|
    canvas.drawSolidLine(i,0,i, 300,3,"red") ;
  }
end


##======================================================================
## main

#test1() ;
#test2() ;
#test3() ;
#test4() ;
#test5() ;
#test6() ;
#test7() ;
#test8() ;
#test9() ;
#test10() ;
test11() ;

	
