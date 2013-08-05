#! /usr/bin/ruby
## -*- Mode: Ruby -*-

require "uconv" ;
require "rexml/document" ;
include REXML ;

$LOAD_PATH.push("~/lib/ruby") ;
require "sexp.rb" ;



#======================================================================
# Syntax
=begin

  <head> body1 body2 </head>    
    <==>  
  (head body1 body2)

  <head attr1="value1" attr2="value2"> body </head> 
    <==>  
  ((head (attr1 "value1") (attr2 "value2")) body)

  <!-- comment -->
    <==>  
  (() "!-- comment -->")

  {any text}
    <==>
  "{any text}"

=end

#======================================================================
# SexpXML module

module SexpXML
  #--------------------------------------------------
  def xml2sexp(node)

    if(node.kind_of?(Element)) then

      ## pick-up head
      tag = Uconv.u8toeuc(node.name) ;

      ## convert attributes
      attrs = [] ;
      node.attributes.each{|name,attr|
	attrPair = [Uconv.u8toeuc(name),Uconv.u8toeuc(attr.value)] ;
	attrs.push(Sexp::listByArray(attrPair)) ;
      }

      ## convert head of node
      if(attrs.length==0) then
	head = tag ;
      else
	head = Sexp::cons(tag,Sexp::listByArray(attrs)) ;
      end

      ## convert children
      children = [] ;
      node.each { |child|
	children.push(xml2sexp(child)) ;
      } 
      
      sexp = Sexp::cons(head,Sexp::listByArray(children)) ;

    elsif(node.kind_of?(Comment)) then
      sexp = Sexp::list(Sexp::NIL,
			Uconv.u8toeuc(node.to_s.gsub("\n","\\n"))) ;

    else
      sexp = '"' + Uconv.u8toeuc(node.to_s).gsub("\n","\\n") + '"' ;
    end

    return sexp ;
  end

  #--------------------------------------------------
  def sexp2xml(sexp)
    if(sexp.kind_of?(Sexp) && sexp.cons?()) then
      if(sexp.car().nil?()) then	# comment
	node = Comment.new(sexp.second().to_s.gsub("\\\\n","\n")) ;

      else				# normal node
	if(sexp.car().cons?()) then	#   with attributes
	  head = sexp.caar();
	  node = Element.new(head.to_s) ;
	  
	  attrs = sexp.cdar();
	  attrs.each() {|a|
	    key = a.first().to_s ;
	    value = a.second().to_s ;
	    node.add_attribute(key,value) ;
	    attrs = attrs.cdr() ;
	  }
	else				#    without attributes
	  head = sexp.car() ;
	  node = Element.new(head.to_s) ;
	end

	#children
	children = sexp.cdr() ;
	children.each(){|c|
	  child = sexp2xml(c) ;
	  node.add(child) ;
	}
      end
    else				# terminal node (text)
      text = sexp.to_s ;
      l = text.length() ;
      node = Text.new(Uconv.euctou8(text[1,l-2].gsub("\\\\n","\n"))) ;
    end
    return node ;
  end
end

#======================================================================
# Sample Data

$SexpXmlSampleXMLData = <<__END_OF_DATA__
<html>
<head>
<title> This is a pen. </title>

<DefNode tag="foo" bar="baz">
	<a x="y" z="&_bar;">
	bar
	<b _restargs_="*"/>
	<InsertBody/>
	</a>
</DefNode>

<DefSubst mainColor="black" subColor="white"/>


</head>
<body bgcolor="&_mainColor;" text="&_subColor;" link="red" vlink="blue">

<Include file="bsub.html"/>

aaa
<table></table>

<foo>kkk</foo>

<table>
 <tr>
  <td>
   a
  </td>
 </tr>
 <tr> <td> 
  b 
  <table>
   <tr><td>
    c
   </td></tr>
  </table>
 </td> </tr>
</table>

bbb

<foo bar="barabara" who="you" sports="soccer"> </foo>
<foo> </foo>

<!-- --------------------------------------------------
  -- test embodiex insert body?
  -->

<DefNode tag="foo">
  <f>
    <InsertBody/>
  </f>
</DefNode>

<DefNode tag="bar">
  <b>
    <InsertBody/>
    <foo>
      <InsertBody/>
    </foo>
  </b>
</DefNode>

<bar>
  This is a test.
</bar>

<!-- --------------------------------------------------
  -- test xpath 
  -->

<DefNode tag="baz">
  <InsertBody xpath="bbb"/>
  <InsertBody xpath="aaa"/>
  <InsertBody xpath="ccc" xpathOpType="first"/>
</DefNode>

<baz>
  <aaa> this is first aaa </aaa>
  <bbb> this is first bbb </bbb>
  <ccc> this is first ccc </ccc>
  <aaa> this is second aaa </aaa>
  <bbb> this is second bbb </bbb>
  <ccc> this is second ccc </ccc>
  <aaa> this is third aaa </aaa>
  <bbb> this is third bbb </bbb>
  <ccc> this is third ccc </ccc>
</baz>

<!-- --------------------------------------------------
  -- test if
  -->

<If type="bool" x="yes">
  <Then>
    [test 1] It is True !!!
  </Then>
  <Else>
    [test 1] It is not True !!!
  </Else>
</If>

<If type="bool" x="no">
  <Then>
    [test 2] It is True !!!
  </Then>
  <Else>
    [test 2] It is not True !!!
  </Else>
</If>

</body>
</html>
__END_OF_DATA__


#======================================================================
# for test

include SexpXML ;
doc = Document.new($SexpXmlSampleXMLData) ;
sexp = xml2sexp(doc) ;
$stdout << sexp.to_s << "\n" ;
newdoc = sexp2xml(sexp) ;
$stdout << Uconv.u8toeuc(newdoc.to_s) << "\n" ;







