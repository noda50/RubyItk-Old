#! /usr/bin/ruby -d
## -*- Mode: Ruby -*-
##Header:
##Title: Itsuki's Text Markup Language processor
##Author: Itsuki Noda
##Type: class definition
##Date: 2004/12/01
##EndHeader:
##

##--------------------------------------------------
## Usage:
=begin
	see itml2html
=end


##--------------------------------------------------
## History:

=begin

 * [2004/02/11:I.Noda]
   separate itml2.rb and itml2html. 

 * [2004/02/11:I.Noda] 
   delete insertAttr sample.  DoSubst provides the same facility.

 * [2004/05/05:I.Noda]
   add equal operation in If.

 * [2004/05/05:I.Noda]
   add <RubyForm>

 * [2004/05/06:I.Noda]
   reader's bug?  if attributes include "xml:lang", then reader make 
   hash table as a attribute value.

=end


##----------------------------------------------------------------------
## Memo
=begin

= itml (Inline Transformation Markup Language)
Privately Extended HTML.

== Inclusion
Include another file.

: Format
    <Include file="subfile.itml">

== Define & Recall
Define a new node format and recall the format later.

=== Define

: Format
    <DefNode tag="foo" baz1="default1" baz2="default2">
      <bar bar_arg1="&_baz1;" _restargs_="*">
      <bar2 bar_arg2="&_baz2;"/>
        <InsertBody/>
      </bar>
    </DefNode>

: Description
  Define a new node whose name is specifiled by "tag" attribute.
  Other attributes are stored to the local database.

  In the body of the definition, 
  <InsertBody/> is replaced by the body part of the node
  at the recalled point.
  A string "&_NAME;" occer in attribute value is replaced by
  a stored attribute value in DefNode tag.
    
  '_restargs_="*"' is replaced to the args of the node at the recalled point.

=== Recall

: Format
    <foo baz1="hoge" extraarg1="goo" extraarg2="gol">
      Here you are.
    </foo>

: Output
    <bar bar_arg1="hoge" extraarg1="goo" extraarg2="gol">
      <bar2 bar_arg2="default2"/>
      Here you are.
    </bar>

: Description
  The defined node can be recalled as above.

== Subst

=== Define

: Format

    <DefSubst soccer="football"/>

: Recall

    <sports name="&_soccer;"> </sports>

: Output

    <sports name="football"> </sports>

: Description

  Define a attribute substitution.

=== Recall as Text

: Format

    <DoSubst label="soccer"/>

: Output

    football

: Description

  recall defined subst as a text entry.

== Eval and Escape Eval

: Format
    
    <DefNode tag="PageTitle">
      <Eval>
        <EscapeEval>
          <DefNode tag="PageTitleBody">
  	    <Eval><InsertBody/></Eval>
          </DefNode>
        </EscapeEval>
      </Eval>
    </DefNode>

    <PageTitle> My Home Page </PageTitle>

: Output 

    * [first step] (in EscapeEval)

      <DefNode tag="PageTitleBody">
        My Home Page
      </DefNode>

== If

: Format

    <If type="{Type}" x="XVal" y="YVal" ...>
      <Then> Then-Text </Then>
      <Else> Else-Text </Else>
    </If>

   {Type} ::= bool 	;; switch by XVal
            | equal	;; equal XVal and YVal
            | ...
: Output

    Then-Text
    Else-Text

== RubyForm

: Format

   <RubyForm>
     Any Ruby Form
   </RubyForm>

: Output

   return value of ruby

=end

##----------------------------------------------------------------------
## includes

$useEuc = false ;

require "tempfile" ;

require "uconv" ;
#require "rexml_EUC/document" ;
require "rexml/document" ;
include REXML ;

##======================================================================
## class ItmlProcessor
class ItmlProcessor

  ##----------------------------------------------------------------------
  ## constants

  ##----------------------------------------
  ## tag names for special nodes of ITML

  Tag_Define = "DefNode" ;
  Tag_DefSubst = "DefSubst" ;
  Tag_Body = "InsertBody" ;
  Tag_Include = "Include" ;
  Tag_DoSubst = "DoSubst" ;

  Tag_Undefined = "UNDEFINED" ;	# used to enclose multiple nodes
  Tag_Dummy = Tag_Undefined ;	# same as undefined

  Tag_EscapeAll = "EscapeAll" ;
  Tag_EscapeEval = "EscapeEval" ;
  Tag_Eval = "Eval" ;

  Tag_If = "If" ;
  Tag_Then = "Then" ;
  Tag_Else = "Else" ;

  Tag_RubyForm = "RubyForm" ;

  ##----------------------------------------
  ## dummy node strings

  DummyNodeStrBegin = "<" + Tag_Dummy + ">" ;
  DummyNodeStrEnd = "</" + Tag_Dummy + ">" ;

  ##----------------------------------------
  ## special attribute names

  Attr_Tag = "tag" ;		# used in <DefNode>
  Attr_File = "file" ;		# used in <Include>
  Attr_Label = "label" ;	# used in <DoSubst>
  Attr_Rest = "_restargs_" ;	# used in realizing Defined Nodes
  Attr_Pointer = "_pointer_" ;	# internal use in <InsertBody>

  Attr_XPath = "xpath" ;        # xpath specification in <InsertBody>
  Attr_XPathOpType = "xpathOpType" ;# xpath operation type {all | first | none}

  ArgFormat = Regexp::new("\&\_([a-zA-Z0-9_]*)\;") ;	# substText pattern

  SubstTableName = "ITML_BaseNode" ;	# system researved subst table

  Attr_Type = "type" ;		# used in <If>
  Attr_X = "x" ;		# used in <If>
  Attr_Y = "y" ;		# used in <If>

  ##----------------------------------------------------------------------
  ## class variables

  attr :substTable, true ;
  attr :defTableDefNode, true ;
  attr :defaultBodyStack, true ;

  ##----------------------------------------------------------------------
  ## initialize

  def initialize()
    setup() ;
  end

  ##----------------------------------------
  ## set variables

  def setup

    @substTable = Element::new(SubstTableName) ;

    @defaultBodyStack = Array.new() ;
    @defaultBodyStack.push(@substTable) ;

    @substTableDefNode = Element::new(Tag_Define) ;
    @substTableDefNode.add_attribute(Attr_Tag,SubstTableName) ;

    @defTable = Hash.new() ;
    putDefine(@substTableDefNode);

  end

  ##----------------------------------------------------------------------
  ## main procedure

  ##----------------------------------------
  ## main procedure for stream with standard html header

  def mainWithStreamWithHtmlHeader(istr,ostr)

    ## output standard header for html
    ## these headers cause error on IE
#   ostr << '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' ;
#    ostr << '<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#               "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' ;
#    ostr << "\n" ;
    ostr << '<!-- This file is generated by ' << $0 << "." ;
    ostr << " [" << Time.now << "] " << '-->' << "\n" ;

    mainWithStream(istr,ostr) 
  end

  ##----------------------------------------
  ## main procedure for stream

  def mainWithStream(istr,ostr)
    input = readAllAsUTF8(istr) ;

    result = mainWithString(input) ;

    ostr << result << "\n" ;
  end

  ##----------------------------------------
  ## main procedure for string

  def mainWithString(str)

    input = DummyNodeStrBegin + str + DummyNodeStrEnd ;

    doc = Document.new(input) ;

    newdoc = convert(doc) ;

    result = ($useEuc ? Uconv.u8toeuc(newdoc.to_s) : newdoc.to_s) ;
    result.sub!(DummyNodeStrBegin,'') ;
    result.sub!(DummyNodeStrEnd,'') ;

    return result ;

  end

  ##----------------------------------------------------------------------
  ## cheking

  ##------------------------------
  ## check <DefNode>

  def isDefine?(node) 
    return node.name == Tag_Define ;
  end

  ##------------------------------
  ## check <DefSubst>

  def isDefSubst?(node) 
    return node.name == Tag_DefSubst ;
  end

  ##------------------------------
  ## check <DoSubst>

  def isDoSubst?(node) 
    return node.name == Tag_DoSubst ;
  end

  ##------------------------------
  ## check <InsertBody>

  def isInsertBody?(node)
    return node.name == Tag_Body ;
  end

  ##------------------------------
  ## check defined nodes

  def isDefinedNode?(node)
    return @defTable.key?(node.name) ;
  end

  ##------------------------------
  ## check <Include>

  def isInclude?(node) 
    return node.name == Tag_Include ;
  end

  ##------------------------------
  ## check dummy (undefined) nodes

  def isDummyNode?(node) 
    return node.name == Tag_Dummy ;
  end

  ##------------------------------
  ## isEscapeAll?

  def isEscapeAll?(node) 
    return node.name == Tag_EscapeAll ;
  end

  ##------------------------------
  ## isEscapeEval?

  def isEscapeEval?(node) 
    return node.name == Tag_EscapeEval ;
  end

  ##------------------------------
  ## isEscapeEval?

  def isEval?(node) 
    return node.name == Tag_Eval ;
  end

  ##------------------------------
  ## isIf?

  def isIf?(node) 
    return node.name == Tag_If ;
  end

  ##------------------------------
  ## isRubyForm?

  def isRubyForm?(node) 
    return node.name == Tag_RubyForm ;
  end

  ##----------------------------------------------------------------------
  ## define operation

  ##------------------------------
  ## put defined node to the def table

  def putDefine(defnode)
    tagname = defnode.attributes[Attr_Tag] ;
    
    if(!tagname) then
      $stderr << "Warning: no tagname in :" << "\n" << defnode << "\n" ;
      return FALSE
    end
    
    @defTable[tagname] = defnode ;
    return TRUE ;
  end

  ##------------------------------
  ## get definition of a defined node from the def table

  def getDefine(node)
    return @defTable[node.name] ;
  end

  ##------------------------------
  ## put subst entry to the subst table

  def putDefSubst(defnode)
    defnode.attributes.each {|name,attr|
      ###[2004/02/09:Noda] is change REXML structure?
      # @substTable.add_attribute(name,attr.value) ; 
      @substTable.add_attribute(name,attr);
    }
  end

  ##----------------------------------------------------------------------
  ## insert operation

  ##------------------------------
  ## assign insert body pointer in body stack

  def assignInsertBodyPointer(node,bodyStack) 

    pointer = bodyStack.length - 1 ;

    if(node.kind_of?(Element)) then
      if(isInsertBody?(node)) then
	node.add_attribute(Attr_Pointer,pointer.to_s) ;
      end
      
      node.each{|e|
	assignInsertBodyPointer(e,bodyStack) ;
      }
    end

  end

  ##------------------------------
  ## doInsertBody

  def doInsertBody(node,result,bodyStack)
    
    pointer = node.attributes[Attr_Pointer].to_i ;

    body = bodyStack[pointer] ;

    xpath = node.attributes[Attr_XPath] ;
    xpathOpType = node.attributes[Attr_XPathOpType] ;

    if(xpath.nil?) then			# if no xpath, none opertion
      xpathOpType = 'none' ;
    else
      if(xpathOpType.nil?) then		# default setting of xpathOpType
	xpathOpType = 'all' ;
      end
    end

    case xpathOpType
    when 'none'
      body.each { |child|
	translate(child,result,bodyStack) ;
      }
    when 'all'
      XPath::each(body,xpath){|child|
	child.each { |c|
	  translate(c,result,bodyStack) ;
	}
      }
    when 'first'
      translate(XPath::first(body,xpath),result,bodyStack) ;
    else
      $stderr << "Warning: unknown operation type for xpath in :" << "\n" << node << "\n" ;
    end
  end

  ##------------------------------
  ## callDefinedNode (eval-argument-first version)

  def callDefinedNode(node,result,bodyStack)

    definition = cloneAll(getDefine(node)) ;
    bodyStack.push(node) ;
    assignInsertBodyPointer(definition,bodyStack) ;

    definition.each { |child|
      translate(child,result,bodyStack) ;
    }

    bodyStack.pop() ;
  end

  ##----------------------------------------------------------------------
  ## substitution operation 

  ##------------------------------
  ## subst text (top)

  def substText(text,bodyStack)
    if(text.kind_of?(Text)) 
      rawtext = text.string ;
    elsif(text.kind_of?(Attribute))
      rawtext = text.value ;
    elsif(text.kind_of?(String))
      rawtext = text ;
    else
      $stderr << "Warning: strange text!!! : " << text.to_s << "\n" ;
      $stderr << "\t" << "This is a " << text.class << " object." << "\n" ;
      rawtext = text.to_s ;
    end

    result = rawtext.clone() ;

#    result.gsub!(ArgFormat) {|dat| 
#      getSubstText($1,bodyStack,dat) ;
#    }
    substTextBody(result,bodyStack) ;

    return result ;
  end

  ##------------------------------
  ## subst text (body)

  def substTextBody(text,bodyStack)
    replacep = FALSE ;
    text.gsub!(ArgFormat) {|dat|
      r = getSubstText($1,bodyStack,dat) ;
      replacep = TRUE if(r != dat) ;
      r
    }

    # call recursively
    if(replacep) then
      substTextBody(text,bodyStack) ;
    end
  end

  ##------------------------------
  ## get subst string

  def getSubstText(key,bodyStack,defaultValue)
    bodyStack.reverse_each { |body|
      substtab1 = body.attributes ;
      substtab2 = getDefine(body).attributes ;
      r = substtab1[key] || substtab2[key] ;
      return r if(r) ;
    }
    return defaultValue ;
  end

  ##------------------------------
  ## subst rest attributes

  def substRestAttr(node,newnode,orgattr,bodyStack)

    body = bodyStack.last ;

    if(body) then
      defattrs = getDefine(body).attributes ;
      body.attributes.each{|name,attr|
	if(!defattrs.key?(name)) then
	  ###[2004/02/09:Noda] is change REXML structure?
	  # newnode.add_attribute(name,attr.value) ;
	  newnode.add_attribute(name,attr) ;
	end
      }
    end

    newnode.delete_attribute(Attr_Rest) ;
  end

  ##------------------------------
  ## insertSubstText

  def doDoSubst(node,result,bodyStack)
    label = node.attributes[Attr_Label] ;
    subst = getSubstText(label,bodyStack,"")
    
    newnode = Text.new(subst) ;

    result.add(newnode) ;
  end

  ##----------------------------------------------------------------------
  ## include

  def doInclude(node,result,bodyStack)
    filename = getAttrWithSubst(node,Attr_File,bodyStack) ;
    if(!filename) then
      $stderr << "Warning: no filename in :" << "\n" << node << "\n" ;
      return node ;
    end

    input = readAllAsUTF8(File.new(filename)) ;
    input = DummyNodeStrBegin + input + DummyNodeStrEnd + "\n" ;

    doc = Document.new(input) ;

    translate(doc,result,bodyStack) ;

  end

  ##----------------------------------------------------------------------
  ## escape eval all

  def escapeAll(node,result,bodyStack)

    node.each { |child|
      newchild = child.clone() ;
      child.attributes.each { |name,attr|
	newchild.add_attribute(name,attr) ;
      }
      escapeAll(child,newchild,bodyStack) ;
      result.add(newchild) ;
    }

  end

  ##----------------------------------------------------------------------
  ## escape eval

  def escapeEval(node,result,bodyStack)

    node.each { |child|
      escapeEvalSub(child,result,bodyStack) ;
    }

  end

  def escapeEvalSub(node,result,bodyStack)
    if(node.kind_of?(Element)) then
      if(isEval?(node)) then
	doEval(node,result,bodyStack) ;
      else
	newnode = node.clone() ;
	node.attributes.each{ |name,attr|
	  newnode.add_attribute(name,attr) ;
	}
	node.each { |child| 
	  escapeEvalSub(child,newnode,bodyStack) ; 
	}
	result.add(newnode) ;
      end
    end
  end
  
  ##----------------------------------------------------------------------
  ## escape eval all

  def doEval(node,result,bodyStack)

    tempresult = Element.new(Tag_Dummy) ;

    node.each{ |child|
      translate(child,tempresult,bodyStack) ;
    }

    tempresult.each{ |newchild|
      translate(newchild,result,bodyStack) ;
    }

  end

  ##----------------------------------------------------------------------
  ## if operation

  def doIf(node,result,bodyStack)

    r = NIL ;

    ifType = node.attributes[Attr_Type] ;
    case ifType
				## boolean switch
    when 'bool'
      yn = node.attributes[Attr_X] ;
      if(yn == 'true' || yn == 'yes') then
	r = TRUE ;
      elsif(yn == 'false' || yn == 'no') then
	r = FALSE ;
      else
	$stderr << "Warning: illegal boolean value in <If> clause: " << yn << "\n" << "\t in : " << node << "\n" ;
      end
				## equal
    when 'equal'
      xval = node.attributes[Attr_X] ;
      yval = node.attributes[Attr_Y] ;
      r = (xval == yval) ;
				## unknown if type
    else
      $strerr << "Warning: illegal IF type: " << ifType << "\n" << node << "\n";
    end
				## BODY
    if(!r.nil?) then
      if(r) then
	XPath::each(node,Tag_Then){|child|
	  child.each{|c|
	    translate(c,result,bodyStack) ;
	  }
	}
      else
	XPath::each(node,Tag_Else){|child|
	  child.each{|c|
	    translate(c,result,bodyStack) ;
	  }
	}
      end
    else
      # do nothing
    end
  end

  ##----------------------------------------------------------------------
  ## ruby form

  def doRubyForm(node,result,bodyStack)
    form = '' ;
    node.each{ |child|
      form += child.to_s ;
    }
    r = eval(form) ;
    if(!r.nil?) then
      rform = ($useEuc ? Uconv.euctou8(r.to_s) : r.to_s);
      rform = DummyNodeStrBegin + rform + DummyNodeStrEnd + "\n" ;
    
      rval = Document.new(rform) ;
      translate(rval,result,bodyStack) ;
    end
  end

  ##----------------------------------------------------------------------
  ## utility

  ##------------------------------
  ## get attribute with subst

  def getAttrWithSubst(node,attrName,bodyStack) 
    attrValue = node.attributes[attrName] ;
    if(attrValue) then
      return substText(attrValue,bodyStack) ;
    else
      return nil ;
    end
  end

  ##------------------------------
  ## clone node deeply

  def cloneAll(node,bodyStack = @defaultBodyStack,substp = FALSE)
    newnode = node.clone() ;
    if(node.kind_of?(Element)) then
      node.each { |e|
	newnode.add(cloneAll(e,bodyStack,substp)) ;
      }
      node.attributes.each {|key,attr|
	if(substp) then
	  translateAttribute(node,newnode,key,attr,bodyStack) ;
	else
	  ###[2004/02/09:Noda] is change REXML structure?
	  # newnode.add_attribute(key,attr.value) ;
	  newnode.add_attribute(key,attr) ;
	end
      }
    end
    return newnode ;
  end

  ##--------------------------------
  ## readAllAsUTF8(strm)

  def readAllAsUTF8(strm)
    input = "" ;
    while(strm.gets())
      input.concat(($useEuc ? Uconv.euctou8($_) : $_)) ;
    end
    return input ;
  end

  ##----------------------------------------------------------------------
  ## translate

  ##------------------------------
  ## eval top

  def convert(doc)
    result = Element.new(Tag_Dummy) ;

    translate(doc,result,@defaultBodyStack) ;

    return result ;
  end

  ##------------------------------
  ## translate body

  def translate(node, result, 
		bodyStack = @defaultBodyStack)

    if(node.kind_of?(Element)) then

      if(isDefine?(node)) then
	putDefine(node) ;

      elsif(isDefSubst?(node)) then
	putDefSubst(node) ;

      elsif(isDoSubst?(node)) then
	doDoSubst(node,result,bodyStack) ;

      elsif(isInsertBody?(node)) then
	doInsertBody(node,result,bodyStack) ;

      elsif(isInclude?(node)) then
	doInclude(node,result,bodyStack) ;

      elsif(isEval?(node)) then
	doEval(node,result,bodyStack) ;

      elsif(isEscapeAll?(node)) then
	escapeAll(node,result,bodyStack) ;

      elsif(isEscapeEval?(node)) then
	escapeEval(node,result,bodyStack) ;

      elsif (isDefinedNode?(node)) then
	callDefinedNode(node,result,bodyStack) ;

      elsif (isIf?(node)) then
	doIf(node,result,bodyStack) ;

      elsif (isRubyForm?(node)) then
	doRubyForm(node,result,bodyStack) ;

      elsif (isDummyNode?(node)) then
	node.each { |child|
	  translate(child,result,bodyStack) ;
	}

      else
	newnode = node.clone() ;
	node.attributes.each { |name,attr|
	  translateAttribute(node,newnode,name,attr,bodyStack) ;
	}
	node.each { |child|
	  translate(child,newnode,bodyStack) ;
	}
	result.add(newnode) ;
      end
      #  elsif(node.kind_of?(Comment)) 
      #    newcomment = Comment.new(node.to_s) ;
      #    result.add(newcomment) ;
    else  # Text
      newtext = node.clone() ;
      result.add(newtext) ;
    end
    return result ;
  end

  ##------------------------------
  ## translate attribute

  def translateAttribute(node,newnode,name,attr,bodyStack)
    if(name == Attr_Rest) then
      substRestAttr(node,newnode,attr,bodyStack) ;
    else
      attr = attr[name] if(attr.is_a?(Hash)) ;

      ###[2004/02/09:Noda] is change REXML structure?
      # newval = substText(attr.value,bodyStack) ;

      newval = substText(attr,bodyStack) ;
      newnode.add_attribute(name,newval) ;
    end
  end

  ##----------------------------------------------------------------------
  ## scan

  def scanFile(filename)
    document = Document.new(File.new(filename)) ;
    document = convert(document) ;
    return document ;
  end

  ##----------------------------------------------------------------------
  ## showInSexp

  ##----------------------------------------
  ## showInSexp top

  def showInSexp(node,strm=$stderr,indent=0)
    showInSexpBody(node,strm,indent) ;
    strm << "\n" ;
  end

  ##----------------------------------------
  ## showInSexp body

  def showInSexpBody(node,strm=$stderr,indent=0)
    if(node.kind_of?(Element)) then
      strm << "(" ; 

      strm << "(" << ($useEuc ? Uconv.u8toeuc(node.name.to_s) : node.name.to_s)
      node.attributes.each {|label,value|
	#      strm << " (" << Uconv.u8toeuc(label.to_s) << " " ;
	#      strm << Uconv.u8toeuc(value.to_s) << ")" ;
	strm << " " << ($useEnc ? Uconv.u8toeuc(value.to_s) : value.to_s);
      }
      strm << ")" ;
      
      #    node.elements.each { |child|
      node.each { |child|
	strm << "\n" ;
	(0...indent+1).each { strm << " " ; } ;
	showInSexpBody(child,strm,indent+1) ;
      }

      strm << ")" ;
    elsif(node.kind_of?(Comment)) then
      strm << '"<!--' << ($useEuc ? Uconv.u8toeuc(node.to_s) : node.to_s).gsub("\n","\\n") << '-->"';
    else
      strm << '"' << ($useEuc ? Uconv.u8toeuc(node.to_s) : node.to_s).gsub("\n","\\n") << '"';
    end
  end

end
    
#======================================================================
# Sample Data
$ItmlSampleData = <<__Itml_Sample_Data_End__

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

<!-- --------------------------------------------------
  -- test ruby form
  -->
<RubyForm>
#<!--
  $x = 1 ;
  NIL ;
#-->
</RubyForm>
<RubyForm>
#<!--
  if($x > 3) then
    '<p> aho </p>' ;
  else
    '<p> baka </p>' ;
  end
#-->
</RubyForm>

</body>
</html>
__Itml_Sample_Data_End__
